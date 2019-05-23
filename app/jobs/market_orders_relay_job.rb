class MarketOrdersRelayJob < ApplicationJob
  queue_as :default

  def perform(order)
    locals = { type: 'update', channel: 'market_orders', request_id: 'abc', payload: [order] }
    response = ApplicationController.render('orders/socket', locals: locals)
    ActionCable.server.broadcast("market_orders:#{order.market.symbol}", response)
  end
end
