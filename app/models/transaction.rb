class Transaction < ApplicationRecord
  belongs_to :transactable, :polymorphic => true

  before_create :assign_next_nonce
  after_create :broadcast

  def self.confirm_mined_transactions
    client = Ethereum::Singleton.instance
    key = Eth::Key.new(priv: ENV['PRIVATE_KEY'].hex)
    @last_confirmed_nonce ||= client.get_nonce(key.address) - 1
    mined_transactions = self.where.not({ :status => 'confirmed' }).where({ :nonce => 0..@last_confirmed_nonce })
    mined_transactions.each do |transaction|
      transaction_receipt = client.eth_get_transaction_by_hash(transaction.transaction_hash)['result']
      if !transaction_receipt
        raise 'transaction receipt not found'
      end
      block_number = transaction_receipt['blockNumber'].hex
      block_hash = transaction_receipt['blockHash']
      gas = transaction_receipt['gas'].hex
      transaction.update!({ :status => 'confirmed', :block_number => block_number, :block_hash => block_hash, :gas => gas })
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

  def self.rebroadcast_expired_transactions
    unconfirmed_transactions = self.unconfirmed.sort_by { |transaction| transaction.nonce.to_i }
    unconfirmed_transactions.each do |transaction|
      if !transaction.expired?
        return
      end

      begin
        BroadcastTransactionJob.perform_now(transaction)
      rescue
      end
    end
  end

  def self.unconfirmed
    self.where.not({ :status => "confirmed" })
  end

  def expired?
    client = Ethereum::Singleton.instance
    key = Eth::Key.new(priv: ENV['PRIVATE_KEY'].hex)
    @last_confirmed_nonce ||= client.get_nonce(key.address) - 1
    return self.nonce.to_i >= @last_confirmed_nonce && self.created_at <= 5.minutes.ago
  end

  private

  def assign_next_nonce
    self.nonce = Redis.current.incr('nonce') - 1
  end
end
