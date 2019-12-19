require 'rails_helper'

RSpec.describe AccountOrdersChannel, type: :channel, perform_enqueued: true do
  it "broadcasts a message when an order is created" do
    order = build(:order)

    expect {
      order.save
    }.to have_broadcasted_to("account_orders:#{order.account_address}")
  end
end
