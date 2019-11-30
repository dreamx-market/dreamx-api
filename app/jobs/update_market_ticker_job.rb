class UpdateMarketTickerJob < ApplicationJob
  queue_as :default

  def perform(trade)
    trade.market.ticker.update_data
  end
end
