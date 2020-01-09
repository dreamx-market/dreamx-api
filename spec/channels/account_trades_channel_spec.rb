require 'rails_helper'

RSpec.describe AccountTradesChannel, type: :channel, perform_enqueued: true do
  it "broadcast messages to taker and maker when trades are created and updated", :onchain do
    trade = build(:trade)
    maker = trade.order.account_address
    taker = trade.account_address

    expect {
    expect {
      trade.save
    }.to have_broadcasted_to("account_trades:#{taker}").twice
    }.to have_broadcasted_to("account_trades:#{maker}").twice
  end
end
