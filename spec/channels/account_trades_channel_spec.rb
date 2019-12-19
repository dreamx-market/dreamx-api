require 'rails_helper'

RSpec.describe AccountTradesChannel, type: :channel, perform_enqueued: true do
  it "broadcast a message for both maker and taker when a new trade is created" do
    trade = build(:trade)
    maker = trade.order.account_address
    taker = trade.account_address

    expect {
    expect {
      trade.save
    }.to have_broadcasted_to("account_trades:#{taker}")
    }.to have_broadcasted_to("account_trades:#{maker}")
  end

  it "broadcast a message for both maker and taker when a trade's transaction is updated", :onchain do
    trade = create(:trade)
    maker = trade.order.account_address
    taker = trade.account_address

    expect {
    expect {
      BroadcastTransactionJob.perform_now(trade.tx)
    }.to have_broadcasted_to("account_trades:#{taker}")
    }.to have_broadcasted_to("account_trades:#{maker}")
  end
end
