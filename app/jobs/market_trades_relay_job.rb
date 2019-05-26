class MarketTradesRelayJob < ApplicationJob
  queue_as :default

  def perform(trade)
    locals = { channel: 'MarketTrades', payload: [trade] }
    response = ApplicationController.render('trades/socket', locals: locals)
    ActionCable.server.broadcast("market_trades:#{trade.market_symbol}", response)
  end
end
