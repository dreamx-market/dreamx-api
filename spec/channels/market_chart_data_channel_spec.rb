require 'rails_helper'

RSpec.describe MarketChartDataChannel, type: :channel, perform_enqueued: true do
  it "broadcast a message when a new chart datum is recorded" do
    market_symbol = "ONE_ETH"
    period = 1.hour.to_i

    expect {
      ChartDatum.aggregate(1.hour)
    }.to have_broadcasted_to("market_chart_data:#{market_symbol}:#{period}")
  end
end
