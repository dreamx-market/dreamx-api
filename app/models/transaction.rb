class Transaction < ApplicationRecord
  belongs_to :transactable, :polymorphic => true

  after_create :assign_nonce

  def raw
    client = Ethereum::Singleton.instance
    key = Eth::Key.new(priv: ENV['PRIVATE_KEY'].hex)    
    gas_price = client.eth_gas_price['result'].hex.to_i
    gas_limit = client.eth_get_block_by_number("latest", false)["result"]["gasLimit"].hex.to_i
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
    tx.hex
  end

  # def broadcast
    
  # end

  private

  def assign_nonce
    self.update!({ :nonce => Redis.current.incr('nonce') })
  end
end
