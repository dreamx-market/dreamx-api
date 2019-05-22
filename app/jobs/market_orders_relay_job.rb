class MarketOrdersRelayJob < ApplicationJob
  queue_as :default

  def perform(market, order)
    CommentsChannel.broadcast_to(market, order)
  end
end
