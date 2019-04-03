class BroadcastTransactionJob < ApplicationJob
  queue_as :default

  def perform(tx)
    client = Ethereum::Singleton.instance
    tx_hash = client.eth_send_raw_transaction(tx.raw.hex)["result"]
    tx.update!({ 
      :gas_limit => tx.raw.gas_limit, 
      :gas_price => tx.raw.gas_price, 
      :transaction_hash => tx_hash, 
      :status => 'unconfirmed' 
    })
  end
end
