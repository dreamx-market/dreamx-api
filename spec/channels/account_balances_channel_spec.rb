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
    order = build(:order)

    expect {
      order.save
    }.to have_broadcasted_to("account_balances:#{order.account_address}")
  end

  it "broadcasts a message when an order is cancelled" do
    cancel = build(:order_cancel)
    
    expect {
      cancel.save
    }.to have_broadcasted_to("account_balances:#{cancel.account_address}")
  end

  it "broadcasts 2 messages, 1 for give balance and 1 for take balance when a trade is created" do
    trade = build(:trade)

    expect {
      trade.save
    }.to have_broadcasted_to("account_balances:#{trade.account_address}").twice
  end
end
