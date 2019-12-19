require 'rails_helper'

RSpec.describe MarketTickersChannel, type: :channel, perform_enqueued: true do
  it "broadcasts a message when a ticker has been updated by a trade" do
    trade = build(:trade)

    expect {
      trade.save
    }.to have_broadcasted_to("market_tickers")
  end

  it "broadcasts a message when a ticker has been updated by an order or order cancel" do
    order = build(:order, :sell)

    expect {
      order.save
    }.to have_broadcasted_to("market_tickers")

    expect {
      create(:trade, order: order)
    }.to have_broadcasted_to("market_tickers")
  end
end
