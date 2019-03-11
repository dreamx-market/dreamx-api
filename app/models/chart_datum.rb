class ChartDatum < ApplicationRecord
  def self.aggregate(period)
    @markets ||= Market.all
    @markets.each do |market|
      open_price = market.chart_data.last ? market.chart_data.last.close : nil
      new_chart_datum = {
        :high => market.high(period) || open_price,
        :low => market.low(period) || open_price,
        :open => open_price,
        :close => market.last_price(period) || open_price,
        :volume => market.volume(period),
        :quote_volume => market.quote_volume(period),
        :average => market.average_price(period) || open_price,
        :period => period.to_s,
        :market_symbol => market.symbol,
      }
      pp new_chart_datum
      self.create!(new_chart_datum)
    end
  end
end
