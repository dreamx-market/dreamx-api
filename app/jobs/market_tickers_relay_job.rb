class MarketTickersRelayJob < ApplicationJob
  queue_as :default

  def perform(ticker)
    locals = { channel: 'MarketTickers', payload: [ticker] }
    json = JSON.parse(ApplicationController.render('tickers/socket', locals: locals))
    ActionCable.server.broadcast("market_tickers:#{ticker.market_symbol}", json)
  end
end
