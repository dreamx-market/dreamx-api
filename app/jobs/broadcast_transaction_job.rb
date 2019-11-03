class BroadcastTransactionJob < ApplicationJob
  queue_as :default

  def perform(tx)
    client = Ethereum::Singleton.instance
    client.eth_send_raw_transaction(tx.hex)["result"]
    tx.update!({ 
      :status => 'unconfirmed',
      :broadcasted_at => Time.now
    })
  end
end
