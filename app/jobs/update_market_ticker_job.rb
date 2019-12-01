class UpdateMarketTickerJob < ApplicationJob
  queue_as :default

  def perform(market)
    market.ticker.update_data
  end
end
