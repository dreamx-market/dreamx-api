class AccountTradesRelayJob < ApplicationJob
  queue_as :default

  def perform(trade)
    locals = { channel: 'AccountTrades', payload: [trade] }
    json = ApplicationController.render('trades/socket', locals: locals)
    ActionCable.server.broadcast("account_trades:#{trade.maker_address}", json)
    ActionCable.server.broadcast("account_trades:#{trade.taker_address}", json)
  end
end
