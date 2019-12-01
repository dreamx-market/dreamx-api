class Ticker < ApplicationRecord
  validates :market_symbol, uniqueness: true
  belongs_to :market, class_name: 'Market', foreign_key: 'market_symbol', primary_key: 'symbol'

  after_commit { MarketTickersRelayJob.perform_later(self) }

  class << self
  end

  def update_data
    ticker = self.build_ticker
    self.assign_attributes(ticker)
    if self.changed?
      self.save
    end
  end

  def build_ticker
    ticker = {
      :market_symbol => self.market.symbol,
      :last => self.market.last_price ? self.market.last_price.to_s : nil,
      :high => self.market.high ? self.market.high.to_s : nil,
      :low => self.market.low ? self.market.low.to_s : nil,
      :lowest_ask => self.market.lowest_ask ? self.market.lowest_ask.to_s : nil,
      :highest_bid => self.market.highest_bid ? self.market.highest_bid.to_s : nil,
      :percent_change => self.market.percent_change_24h.to_s,
      :base_volume => self.market.volume.to_s,
      :quote_volume => self.market.quote_volume.to_s
    }
    return ticker
  end

  private
end
