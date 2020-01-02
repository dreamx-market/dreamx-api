class MarketTradesRelayJob < ApplicationJob
  queue_as :default

  def perform(trade)
    locals = { channel: 'MarketTrades', payload: [trade] }
    json = JSON.parse(ApplicationController.render('trades/socket', locals: locals))
    ActionCable.server.broadcast("market_trades:#{trade.market.symbol}", json)
  end
end
