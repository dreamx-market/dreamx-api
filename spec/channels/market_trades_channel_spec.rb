require 'rails_helper'

RSpec.describe MarketTradesChannel, type: :channel, perform_enqueued: true do
  it "broadcasts a message when a new trade is created" do
    trade = build(:trade)

    expect {
      trade.save
    }.to have_broadcasted_to("market_trades:#{trade.market_symbol}")
  end
end
