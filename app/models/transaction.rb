class Transaction < ApplicationRecord
  belongs_to :transactable, :polymorphic => true

  before_create :assign_next_nonce
  after_create :broadcast

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
    last_confirmed_nonce = client.get_nonce(key.address)
    return self.nonce.to_i >= last_confirmed_nonce && self.created_at <= 5.minutes.ago
  end

  private

  def assign_next_nonce
    self.nonce = Redis.current.incr('nonce') - 1
  end
end
