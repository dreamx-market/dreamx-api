class BroadcastTransactionJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # generate raw transaction
    # broadcast raw transaction
    # update transaction record upon success
  end
end
