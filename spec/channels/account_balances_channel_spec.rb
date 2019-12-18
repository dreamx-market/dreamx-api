require 'rails_helper'

RSpec.describe AccountBalancesChannel, type: :channel, perform_enqueued: true do
  it "broadcasts a message when a new deposit is created" do
    deposit = build(:deposit)

    expect {
      deposit.save
    }.to have_broadcasted_to("account_balances:#{deposit.account_address}")
  end

  it "broadcasts a message when a new withdrawal is created" do
    withdraw = build(:withdraw)

    expect {
      withdraw.save
    }.to have_broadcasted_to("account_balances:#{withdraw.account_address}")
  end

  it "broadcasts a message when a new order is created" do
    order = build(:buy_order)

    expect {
      order.save
    }.to have_broadcasted_to("account_balances:#{order.account_address}")
  end
end
