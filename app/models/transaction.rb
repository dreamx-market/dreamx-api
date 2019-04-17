class Transaction < ApplicationRecord
  belongs_to :transactable, :polymorphic => true

  before_create :assign_next_nonce
  after_create :broadcast

  def self.confirm_mined_transactions
    client = Ethereum::Singleton.instance
    key = Eth::Key.new(priv: ENV['PRIVATE_KEY'].hex)
    last_confirmed_nonce = client.get_nonce(key.address) - 1
    last_block_number = client.eth_get_block_by_number('latest', false)['result']['number'].hex
    mined_transactions = self.where({ :status => ["unconfirmed", "pending"] }).where({ :nonce => 0..last_confirmed_nonce })
    mined_transactions.length
    mined_transactions.each do |transaction|
      begin
        transaction_receipt = client.eth_get_transaction_receipt(transaction.transaction_hash)['result']
      rescue
        if !transaction_receipt
          transaction.update!({ :status => 'replaced' })
          ENV['READ_ONLY'] = 'true'
          next
        end
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
  end

  def raw
    client = Ethereum::Singleton.instance
    key = Eth::Key.new(priv: ENV['PRIVATE_KEY'].hex)
    gas_price = client.eth_gas_price['result'].hex.to_i
    gas_limit = ENV['GAS_LIMIT'].to_i
    contract_address = ENV['CONTRACT_ADDRESS']
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
      BroadcastTransactionJob.perform_now(self)
    rescue
    end
  end

  def self.broadcast_expired_transactions
    if (!self.has_unconfirmed_transactions? and self.has_replaced_transactions?)
      self.regenerate_replaced_transactions
    end

    unconfirmed_transactions = self.unconfirmed.sort_by { |transaction| transaction.nonce.to_i }
    unconfirmed_transactions.each do |transaction|
      if !transaction.expired?
        next
      end

      begin
        BroadcastTransactionJob.perform_now(transaction)
      rescue
      end
    end
  end

  def self.regenerate_replaced_transactions
    self.sync_nonce
    replaced_transactions = self.replaced.sort_by { |transaction| transaction.nonce.to_i }
    replaced_transactions.each do |transaction|
      next_nonce = Redis.current.incr('nonce') - 1
      transaction.update!({ :nonce => next_nonce, :status => "pending" })
    end
    ENV['READ_ONLY'] = 'false'
  end

  def self.has_unconfirmed_transactions?
    self.unconfirmed.first ? true : false
  end

  def self.has_replaced_transactions?
    self.where({ :status => 'replaced' }).first ? true : false
  end

  def self.broadcast_pending_transactions
    pending_transactions = self.pending.sort_by { |transaction| transaction.nonce.to_i }
    pending_transactions.each do |transaction|
      begin
        BroadcastTransactionJob.perform_now(transaction)
      rescue => e
        if ENV['RAILS_ENV'] == 'test' and e.to_s == 'VM Exception while processing transaction: revert'
          # ganache raises an error upon VM exceptions instead of returning the transaction hash
          # so we have to ignore the error and update transaction_hash manually
          client = Ethereum::Singleton.instance
          transaction_hash = client.eth_get_block_by_number('latest', false)['result']['transactions'].first
          transaction.update!({ :transaction_hash => transaction_hash, :status => 'unconfirmed' })
        end
      end
    end
  end

  def self.unconfirmed
    self.where({ :status => ["unconfirmed", "pending"] })
  end

  def self.replaced
    self.where({ :status => ["replaced", "failed"] })
  end

  def self.pending
    self.where({ :status => ["pending"] })
  end

  def expired?
    client = Ethereum::Singleton.instance
    key = Eth::Key.new(priv: ENV['PRIVATE_KEY'].hex)
    last_confirmed_nonce = client.get_nonce(key.address) - 1
    return self.nonce.to_i >= last_confirmed_nonce && self.created_at <= 5.minutes.ago
  end

  private

  def assign_next_nonce
    self.nonce = Redis.current.incr('nonce') - 1
  end

  def self.sync_nonce
    client = Ethereum::Singleton.instance
    key = Eth::Key.new priv: ENV['PRIVATE_KEY'].hex
    Redis.current.set("nonce", client.get_nonce(key.address))
  end
end
