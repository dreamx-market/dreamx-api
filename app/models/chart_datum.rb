class ChartDatum < ApplicationRecord
  validates :period, inclusion: { in: [5.minutes, 15.minutes, 1.hour, 1.day] }

  after_commit { MarketChartDataRelayJob.perform_later(self) }

  def self.aggregate(period)
    markets = Market.all
    markets.each do |market|
      open_price = market.chart_data.last ? market.chart_data.last.close : nil
      new_chart_datum = {
        :market_symbol => market.symbol,
        :high => market.high(period) || open_price,
        :low => market.low(period) || open_price,
        :open => open_price,
        :close => market.last_price(period) || open_price,
        :volume => market.volume(period),
        :quote_volume => market.quote_volume(period),
        :average => market.average_price(period) || open_price,
        :period => period.to_s,
      }
      self.create!(new_chart_datum)
    end
  end

  def self.remove_expired
    chart_data = self.all
    chart_data.each do |chart_datum|
      chart_datum.delete if chart_datum.expired?
    end
  end

  def expired?
    if (self.period == 5.minutes.to_s)
      return self.created_at < Time.current - ENV['CHART_DATUM_EXPIRY_5M'].to_i
    elsif (self.period == 15.minutes.to_s)
      return self.created_at < Time.current - ENV['CHART_DATUM_EXPIRY_15M'].to_i
    elsif (self.period == 1.hour.to_s)
      return self.created_at < Time.current - ENV['CHART_DATUM_EXPIRY_1H'].to_i
    else
      return false
    end
  end
end
