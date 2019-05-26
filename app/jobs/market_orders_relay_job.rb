class MarketOrdersRelayJob < ApplicationJob
  queue_as :default

  def perform(order)
    locals = { channel: 'MarketOrders', payload: [order] }
    response = ApplicationController.render('orders/socket', locals: locals)
    ActionCable.server.broadcast("market_orders:#{order.market_symbol}", response)
  end
end
