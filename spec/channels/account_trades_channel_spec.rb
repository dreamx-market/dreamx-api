require 'rails_helper'

RSpec.describe AccountTradesChannel, type: :channel, perform_enqueued: true do
  it "broadcasts a messages to taker and maker when a new trade is created", :onchain do
    trade = build(:trade)
    maker = trade.order.account_address
    taker = trade.account_address

    expect {
    expect {
      trade.save
    }.to have_broadcasted_to("account_trades:#{taker}")
    }.to have_broadcasted_to("account_trades:#{maker}")
  end
end
