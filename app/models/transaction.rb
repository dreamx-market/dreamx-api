class Transaction < ApplicationRecord
  belongs_to :transactable, :polymorphic => true

  validates :status, inclusion: { in: ['pending', 'unconfirmed', 'confirmed'] }

  before_create :assign_nonce, :sign
  after_create_commit :broadcast
  after_commit :relay_account_transactable, on: :create
  after_commit :relay_market_transactable, on: :create

  scope :confirmed, -> { where(status: 'confirmed') }
  scope :unconfirmed, -> { where(status: 'unconfirmed') }
  scope :pending, -> { where(status: 'pending') }
  scope :unconfirmed_and_pending, -> { where(status: ['unconfirmed', 'pending']) }

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

  def self.confirm_mined_transactions(confirmed_block)
    self.where(transaction_hash: confirmed_block[:transactions]).update_all(status: 'confirmed')
  end

  def self.broadcast_expired_transactions
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

  def expired?
    if (!self.broadcasted_at)
      return true
    end

    return self.broadcasted_at <= 5.minutes.ago && self.status != 'confirmed'
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
