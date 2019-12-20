require 'rails_helper'

RSpec.describe Balance, type: :model do
  it "cannot have negative balance" do
    balance = build(:balance)
    balance.balance = -1
    expect(balance).to_not be_valid
    expect(balance.errors.messages[:balance]).to eq(["must be greater than or equal to 0"])
  end

  it "hold_balance cannot be negative" do
    balance = create(:balance)
    balance.hold_balance = -1
    expect(balance).to_not be_valid
    expect(balance.errors.messages[:hold_balance]).to eq(["must be greater than or equal to 0"])
  end

  it "becomes unauthentic because of invalid deposits" do
    balance = create(:balance)
    deposit = create(:deposit, account: balance.account)
    expect(balance.reload.authentic?).to be(true)
    deposit.amount = deposit.amount.to_i / 2
    deposit.save(validate: false)
    expect(balance.reload.authentic?).to_not be(true)
  end

  it "becomes unauthentic because of invalid withdrawals" do
    balance = create(:balance)
    withdraw = create(:withdraw, account: balance.account)
    expect(balance.reload.authentic?).to be(true)
    withdraw.amount = withdraw.amount.to_i / 2
    withdraw.save(validate: false)
    expect(balance.reload.authentic?).to_not be(true)
  end

  it "becomes unauthentic because of invalid trades" do
    balance = create(:balance)
    trade = create(:trade, account: balance.account)
    expect(balance.reload.authentic?).to be(true)
    trade.amount = trade.amount.to_i / 2
    trade.save(validate: false)
    expect(balance.reload.authentic?).to_not be(true)
  end

  it "becomes unauthentic bacause of invalid hold_balance" do
    balance = create(:balance)
    balance.update({ hold_balance: '1234' })
    expect(balance.reload.authentic?).to_not be(true)
  end

  it "becomes unauthentic because of invalid open orders" do
    balance = create(:balance)
    order = create(:order, :buy, account: balance.account)
    expect(balance.reload.authentic?).to be(true)
    order.give_amount = order.give_amount.to_i / 2
    order.save(validate: false)
    expect(balance.reload.authentic?).to_not be(true)
  end

  it "should not invalidate on refunds" do
    balance = create(:balance)
    expect {
      balance.refund("1".to_wei)
    }.to have_increased { Refund.count }.by(1)
    expect(balance.reload.authentic?).to be(true)
  end

  it "calculates total traded amounts" do
    order = create(:order, :sell)
    trade = build(:trade, order: order)
    balance_with_sell_order = trade.maker_give_balance
    balance_with_buy_order = trade.maker_take_balance
    balance_with_sell_trade = trade.taker_give_balance
    balance_with_buy_trade = trade.taker_take_balance

    expect {
    expect {
    expect {
    expect {
      trade.save
    }.to have_decreased {balance_with_sell_order.total_traded}.by(order.give_amount)
    }.to have_increased {balance_with_buy_order.total_traded}.by(trade.maker_receiving_amount_after_fee)
    }.to have_decreased {balance_with_buy_trade.total_traded}.by(trade.take_amount)
    }.to have_increased {balance_with_sell_trade.total_traded}.by(trade.taker_receiving_amount_after_fee)
  end

  # it "balance altering operations should be threaded", :bypass_cleaner, :focus do
  #   balance = create(:balance)

  #   # Thread.new do
  #   #   balance.credit(1)
  #   # end

  #   # threads = []
  #   # 3.times do
  #   #   thread = Thread.new do
  #   #     balance.credit(1)
  #   #     pp balance.balance
  #   #   end
  #   #   threads.push(thread)
  #   # end
  #   # threads.each(&:join)

  #   # pp balance.reload.balance

  #   concurrently(4) do
  #     balance.credit(1)
  #   end
  #   pp balance.reload.balance
  #   # expect(balance.reload.balance).to eq(4)
  # end
end
