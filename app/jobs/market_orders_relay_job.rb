class MarketOrdersRelayJob < ApplicationJob
  queue_as :default

  def perform(order)
    output = json(order)
    pp JSON.parse(output)
    ActionCable.server.broadcast("market_orders:#{order.market.symbol}", output)
  end

  def json(order)
    ApplicationController.render('orders/socket', locals: { type: 'update', channel: 'market_orders', request_id: 'abc', orders: [order] })
  end
end
