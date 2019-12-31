class Transaction < ApplicationRecord
  belongs_to :transactable, :polymorphic => true

  validates :status, inclusion: { in: ['confirmed', 'unconfirmed', 'pending', 'replaced', 'failed', 'out_of_gas'] }

  before_create :assign_nonce, :sign
  after_create_commit :broadcast
  after_commit :relay_account_transactable, on: :create
  after_commit :relay_market_transactable, on: :create

  scope :replaced, -> { where(status: 'replaced') }
  scope :unconfirmed_and_pending, -> { where(status: ['unconfirmed', 'pending']) }
  scope :unconfirmed, -> { where(status: 'unconfirmed') }
  scope :pending, -> { where(status: 'pending') }

  class << self
    def next_nonce
      Redis.current.get('nonce')
    end

    def next_onchain_nonce
      client = Ethereum::Singleton.instance
      key = Eth::Key.new(priv: ENV['SERVER_PRIVATE_KEY'].hex)
      client.get_nonce(key.address)
    end

    def generate_random_hash
      "0x#{SecureRandom.hex(32)}"
    end
  end

  def self.confirm_mined_transactions
    client = Ethereum::Singleton.instance
    key = Eth::Key.new(priv: ENV['SERVER_PRIVATE_KEY'].hex)
    last_onchain_nonce = client.get_nonce(key.address) - 1
    last_block_number = client.eth_get_block_by_number('latest', false)['result']['number'].hex
    mined_transactions = self.where({ :status => ["unconfirmed", "pending"] }).where({ :nonce => 0..last_onchain_nonce })
    mined_transactions.each do |transaction|
      transaction.with_lock do
        begin
          onchain_transaction = client.eth_get_transaction_by_hash(transaction.transaction_hash)['result']
        rescue
        end
        if !onchain_transaction
          # transaction has a nonce equal to or lesser than last onchain nonce and it is cannot be found on-chain, mark as replaced
          transaction.mark_replaced(last_onchain_nonce)
          transaction.save!
          next
        end
        transaction_receipt = client.eth_get_transaction_receipt(transaction.transaction_hash)['result']
        if !transaction_receipt
          # transaction_receipt hasn't been available, skip
          next
        end
        transaction.block_number = transaction_receipt['blockNumber'].hex
        transaction.block_hash = transaction_receipt['blockHash']
        transaction.gas = transaction_receipt['gasUsed'].hex
        transaction.status = transaction_receipt['status'] == '0x1' ? 'confirmed' : 'failed'
        confirmations_required = ENV['TRANSACTION_CONFIRMATIONS'].to_i
        if last_block_number - transaction.block_number.to_i < confirmations_required
          next
        end
        if transaction.status == 'failed'
          transaction.mark_failed

          if transaction.raw.gas_limit == transaction_receipt['gasUsed'].hex
            transaction.mark_out_of_gas
          end
        end
        transaction.save!
      end
    end
  end

  def mark_replaced(last_onchain_nonce)
    # TEMPORARY
    if ENV['RAILS_ENV'] == 'production'
      Config.set('read_only', 'true')
      AppLogger.log("#{self.transaction_hash} has been replaced")
      self.status = 'replaced'
      return
    end

    self.status = 'replaced'
    Config.set('read_only', 'true')
  end

  def mark_failed
    # TEMPORARY
    if ENV['RAILS_ENV'] == 'production'
      Config.set('read_only', 'true')
      AppLogger.log("#{self.transaction_hash} failed")
      self.status = 'failed'
      return
    end

    self.status = 'failed'
    self.transactable.refund
  end

  def mark_out_of_gas
    # TEMPORARY
    if ENV['RAILS_ENV'] == 'production'
      Config.set('read_only', 'true')
      AppLogger.log("#{self.transaction_hash} ran out of gas")
      self.status = 'out_of_gas'
      return
    end

    self.status = 'out_of_gas'
  end

  def raw
    client = Ethereum::Singleton.instance
    key = Eth::Key.new(priv: ENV['SERVER_PRIVATE_KEY'].hex)
    gas_price = ENV['RAILS_ENV'] != 'test' ? client.eth_gas_price['result'].hex.to_i : 0
    gas_limit = ENV['GAS_LIMIT'].to_i
    contract_address = ENV['CONTRACT_ADDRESS'].without_checksum
    payload = self.transactable.payload
    nonce = self.nonce.to_i
    args = {
      from: key.address,
      to: contract_address,
      value: 0,
      data: payload,
      nonce: nonce,
      gas_limit: gas_limit,
      gas_price: gas_price
    }
    tx = Eth::Tx.new(args)
    tx.sign key
  end

  def broadcast
    begin
      BroadcastTransactionJob.perform_later(self)
    rescue
    end
  end

  def self.broadcast_expired_transactions
    # TEMPORARY: disable automatic replaced transaction handling
    # uncomment later when the work-flow becomes more stable
    # if (self.has_replaced_transactions?)
    #   self.regenerate_replaced_transactions
    # end

    unconfirmed_transactions = self.unconfirmed_and_pending.order(:nonce)
    unconfirmed_transactions.each do |transaction|
      if !transaction.expired?
        next
      end

      begin
        BroadcastTransactionJob.perform_later(transaction)
      rescue
      end
    end
  end

  def self.regenerate_replaced_transactions
    if (self.has_unconfirmed_and_pending_transactions?)
      return
    end

    self.sync_nonce
    replaced_transactions = self.replaced.order(:nonce)
    replaced_transactions.each do |transaction|
      transaction.with_lock do
        transaction.assign_nonce
        transaction.assign_attributes({ :status => "pending", :transaction_hash => nil, :hex => nil })
        transaction.sign_and_save!
      end
    end
    Config.set('read_only', 'false')
  end

  def self.regenerate_unconfirmed_transactions
    Config.set('read_only', 'true')
    self.sync_nonce
    unconfirmed_transactions = self.unconfirmed.order(:nonce)
    unconfirmed_transactions.each do |transaction|
      transaction.with_lock do
        transaction.assign_nonce
        transaction.assign_attributes({ :status => "pending", :transaction_hash => nil, :hex => nil })
        transaction.sign_and_save!
      end
    end
    Config.set('read_only', 'false')
  end

  def self.has_unconfirmed_and_pending_transactions?
    self.unconfirmed_and_pending.length > 0 ? true : false
  end

  def self.has_replaced_transactions?
    self.replaced.length > 0 ? true : false
  end

  def self.broadcast_pending_transactions
    pending_transactions = self.pending.order(:nonce)
    pending_transactions.each do |transaction|
      begin
        BroadcastTransactionJob.perform_later(transaction)
      rescue => e
        if ENV['RAILS_ENV'] == 'test'
          # ganache raises an error upon VM exceptions instead of returning the transaction hash
          # so we have to ignore the error and update transaction_hash manually
          transaction.with_lock do
            if e.to_s.include?('VM Exception while processing transaction: revert')
              client = Ethereum::Singleton.instance
              transaction_hash = client.eth_get_block_by_number('latest', false)['result']['transactions'].first
              transaction.update!({ :transaction_hash => transaction_hash, :status => 'unconfirmed' })
            elsif e.to_s.include?("the tx doesn't have the correct nonce")
              transaction.update!({ :status => 'unconfirmed' })
            else
              transaction.update!({ :status => 'undefined' })
            end
          end
        end
      end
    end
  end

  def expired?
    if (self.status == 'confirmed')
      return false
    end

    if (!self.broadcasted_at)
      return true
    end

    client = Ethereum::Singleton.instance
    key = Eth::Key.new(priv: ENV['SERVER_PRIVATE_KEY'].hex)
    last_confirmed_nonce = client.get_nonce(key.address) - 1
    # only unconfirmed transactions can expire
    return self.nonce.to_i > last_confirmed_nonce && self.broadcasted_at <= 5.minutes.ago
  end

  def sign
    raw = self.raw
    self.hex = raw.hex
    self.transaction_hash = Eth::Utils.bin_to_prefixed_hex(Eth::Utils.keccak256(Eth::Utils.hex_to_bin(raw.hex)))
    self.gas_limit = raw.gas_limit
    self.gas_price = raw.gas_price
  end

  def sign_and_save!
    self.sign
    self.save!
  end

  def assign_nonce
    self.nonce = Redis.current.incr('nonce') - 1
  end

  private

  def self.sync_nonce
    client = Ethereum::Singleton.instance
    key = Eth::Key.new priv: ENV['SERVER_PRIVATE_KEY'].hex
    Redis.current.set("nonce", client.get_nonce(key.address))
  end

  def relay_account_transactable
    if self.transactable_type == 'Trade'
      AccountTradesRelayJob.perform_later(self.transactable)
    end

    if self.transactable_type == 'Withdraw'
      AccountTransfersRelayJob.perform_later(self.transactable)
    end
  end

  def relay_market_transactable
    if self.transactable_type == 'Trade'
      MarketTradesRelayJob.perform_later(self.transactable)
    end
  end
end
