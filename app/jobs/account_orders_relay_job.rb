class AccountOrdersRelayJob < ApplicationJob
  queue_as :default

  def perform(order)
    locals = { channel: 'AccountOrders', payload: [order] }
    json = JSON.parse(ApplicationController.render('orders/socket', locals: locals))
    ActionCable.server.broadcast("account_orders:#{order.account_address}", json)
  end
end
