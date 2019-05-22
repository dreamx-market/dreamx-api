class MarketOrdersRelayJob < ApplicationJob
  queue_as :default

  def perform(order)
    ActionCable.server.broadcast("market_orders:#{order.market.symbol}", order)
  end
end
