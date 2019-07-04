class BroadcastTransactionJob < ApplicationJob
  queue_as :default

  def perform(tx)
    client = Ethereum::Singleton.instance

    logger.debug "broadcasting transaction##{tx.id}"

    transaction_hash = client.eth_send_raw_transaction(tx.raw.hex)["result"]

    logger.debug "broadcasted transaction##{tx.id}"

    tx.update!({ 
      :gas_limit => tx.raw.gas_limit, 
      :gas_price => tx.raw.gas_price, 
      :transaction_hash => transaction_hash, 
      :status => 'unconfirmed' 
    })
  end
end
