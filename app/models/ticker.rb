class Ticker < ApplicationRecord
  validates :market_symbol, uniqueness: true
  belongs_to :market, class_name: 'Market', foreign_key: 'market_symbol', primary_key: 'symbol'

  after_commit { MarketTickersRelayJob.perform_later(self) }

  class << self
  end

  def update_data
    self.with_lock do
      data = self.aggregate
      self.assign_attributes(data)
      if self.changed?
        self.save!
      end
    end
  end

  def aggregate
    last_price = self.market.last_price
    high = self.market.high
    low = self.market.low
    highest_bid = self.market.highest_bid
    lowest_ask = self.market.lowest_ask

    ticker = {
      :market_symbol => self.market.symbol,
      :last => last_price ? last_price.to_s : nil,
      :high => high ? high.to_s : nil,
      :low => low ? low.to_s : nil,
      :lowest_ask => lowest_ask ? lowest_ask.to_s : nil,
      :highest_bid => highest_bid ? highest_bid.to_s : nil,
      :percent_change => self.market.percent_change_24h.to_s,
      :base_volume => self.market.volume.to_s,
      :quote_volume => self.market.quote_volume.to_s,
    }
    return ticker
  end

  private
end
