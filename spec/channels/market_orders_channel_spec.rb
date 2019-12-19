require 'rails_helper'

RSpec.describe MarketOrdersChannel, type: :channel, perform_enqueued: true do
  it "broadcasts a message when a new order is created or updated" do
    order = build(:order, :sell)

    expect {
      order.save
    }.to have_broadcasted_to("market_orders:#{order.market_symbol}")

    expect {
      create(:trade, order: order)
    }.to have_broadcasted_to("market_orders:#{order.market_symbol}")
  end

  it "broadcasts a message when an order is cancelled" do
    cancel = build(:order_cancel)

    expect {
      cancel.save
    }.to have_broadcasted_to("market_orders:#{cancel.market_symbol}")
  end
end
