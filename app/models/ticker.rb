class Ticker < ApplicationRecord
  validates :market_symbol, uniqueness: true

  class << self
    def find_by_market_symbol(symbol)
      market = Market.find_by({ :symbol => symbol })

      if (!market)
        return
      end

      return build_ticker(market)
    end

    def build_ticker(market)
      ticker = {
        :market_symbol => market.symbol,
        :last => market.last_price ? market.last_price.to_s : nil,
        :high => market.high ? market.high.to_s : nil,
        :low => market.low ? market.low.to_s : nil,
        :lowest_ask => market.lowest_ask ? market.lowest_ask.to_s : nil,
        :highest_bid => market.highest_bid ? market.highest_bid.to_s : nil,
        :percent_change => market.percent_change_24h.to_s,
        :base_volume => market.volume.to_s,
        :quote_volume => market.quote_volume.to_s
      }
      return ticker
    end
  end

  def update_data
    ticker = Ticker.find_by_market_symbol(self.market_symbol)
    self.assign_attributes(ticker)
    if self.changed?
      self.save
    end
  end
end
