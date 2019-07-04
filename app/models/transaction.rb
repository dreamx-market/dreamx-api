class Transaction < ApplicationRecord
  belongs_to :transactable, :polymorphic => true

  before_create :assign_next_nonce
  after_create_commit :broadcast
  after_commit :relay_account_transactable, on: [:create, :update]
  after_commit :relay_market_transactable, on: :create

  def self.confirm_mined_transactions
    client = Ethereum::Singleton.instance
    key = Eth::Key.new(priv: ENV['SERVER_PRIVATE_KEY'].hex)
    last_onchain_nonce = client.get_nonce(key.address) - 1
    last_block_number = client.eth_get_block_by_number('latest', false)['result']['number'].hex
    mined_transactions = self.where({ :status => ["unconfirmed", "pending"] }).where({ :nonce => 0..last_onchain_nonce })
    mined_transactions.each do |transaction|
      begin
        onchain_transaction = client.eth_get_transaction_by_hash(transaction.transaction_hash)['result']
      rescue
      end
      if !onchain_transaction
        # transaction has a nonce equal to or lesser than last onchain nonce and it is cannot be found on-chain, mark as replaced
        transaction.update!({ :status => 'replaced' })
        Config.set('read_only', 'true')
        next
      end
      transaction_receipt = client.eth_get_transaction_receipt(transaction.transaction_hash)['result']
      if !transaction_receipt
        # transaction_receipt hasn't been available, skip
        next
      end
      block_number = transaction_receipt['blockNumber'].hex
      block_hash = transaction_receipt['blockHash']
      gas = transaction_receipt['gasUsed'].hex
      status = transaction_receipt['status'] == '0x1' ? 'confirmed' : 'failed'
      confirmations_required = ENV['TRANSACTION_CONFIRMATIONS'].to_i
      if last_block_number - block_number < confirmations_required
        next
      end
      if status == 'failed'
        transaction.transactable.refund

        if transaction.raw.gas_limit == transaction_receipt['gasUsed'].hex
          status = "out_of_gas"
        end
      end
      transaction.update!({ :status => status, :block_number => block_number, :block_hash => block_hash, :gas => gas })
    end

    pp 'Performed Transaction.confirm_mined_transactions'
  end

  def raw
    client = Ethereum::Singleton.instance
    key = Eth::Key.new(priv: ENV['SERVER_PRIVATE_KEY'].hex)
    gas_price = client.eth_gas_price['result'].hex.to_i
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
    if ENV['RAILS_ENV'] == 'test'
      return
    end

    begin
      BroadcastTransactionJob.perform_later(self)
    rescue
    end
  end

  def self.broadcast_expired_transactions
    if (!self.has_unconfirmed_and_pending_transactions? and self.has_replaced_transactions?)
      self.regenerate_replaced_transactions
    end

    unconfirmed_transactions = self.unconfirmed_and_pending.sort_by { |transaction| transaction.nonce.to_i }
    unconfirmed_transactions.each do |transaction|
      if !transaction.expired?
        next
      end

      begin
        BroadcastTransactionJob.perform_later(transaction)
      rescue
      end
    end

    pp 'Performed Transaction.broadcast_expired_transactions'
  end

  def self.regenerate_replaced_transactions
    self.sync_nonce
    replaced_transactions = self.replaced.sort_by { |transaction| transaction.nonce.to_i }
    replaced_transactions.each do |transaction|
      next_nonce = Redis.current.incr('nonce') - 1
      transaction.update!({ :nonce => next_nonce, :status => "pending", :transaction_hash => nil })
    end
    Config.set('read_only', 'false')
  end

  def self.has_unconfirmed_and_pending_transactions?
    self.unconfirmed_and_pending.first ? true : false
  end

  def self.has_replaced_transactions?
    self.where({ :status => 'replaced' }).first ? true : false
  end

  def self.broadcast_pending_transactions
    pending_transactions = self.pending.sort_by { |transaction| transaction.nonce.to_i }
    pending_transactions.each do |transaction|
      begin
        BroadcastTransactionJob.perform_later(transaction)
      rescue => e
        if ENV['RAILS_ENV'] == 'test'
          # ganache raises an error upon VM exceptions instead of returning the transaction hash
          # so we have to ignore the error and update transaction_hash manually
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

  def self.unconfirmed_and_pending
    self.where({ :status => ["unconfirmed", "pending"] })
  end

  def self.replaced
    self.where({ :status => ["replaced"] })
  end

  def self.pending
    self.where({ :status => ["pending"] })
  end

  def expired?
    client = Ethereum::Singleton.instance
    key = Eth::Key.new(priv: ENV['SERVER_PRIVATE_KEY'].hex)
    last_confirmed_nonce = client.get_nonce(key.address) - 1
    return self.nonce.to_i >= last_confirmed_nonce && self.created_at <= 5.minutes.ago
  end

  private

  def assign_next_nonce
    self.nonce = Redis.current.incr('nonce') - 1
  end

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
