require 'rails_helper'

RSpec.describe Balance, type: :model do
  let (:balance) { build(:balance) }

  it 'must have a unique account_id & token_id combination' do
    balance1 = create(:balance)
    balance2 = build(:balance)
    balance2.account = balance1.account
    balance2.token = balance1.token

    expect {
      balance2.save(validate: false)
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "cannot have negative balance" do
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
    balance = create(:balance, funded: true)
    withdraw = create(:withdraw, account: balance.account)
    expect(balance.reload.authentic?).to be(true)
    withdraw.amount = withdraw.amount.to_i / 2
    withdraw.save(validate: false)
    expect(balance.reload.authentic?).to_not be(true)
  end

  it "becomes unauthentic because of invalid trades" do
    balance = create(:balance, funded: true)
    trade = create(:trade, account: balance.account)
    expect(balance.reload.authentic?).to be(true)
    trade.take_amount = trade.take_amount / 2
    trade.save(validate: false)
    expect(balance.reload.authentic?).to_not be(true)
  end

  it "becomes unauthentic bacause of invalid hold_balance" do
    balance = create(:balance)
    balance.update({ hold_balance: '1234' })
    expect(balance.reload.authentic?).to_not be(true)
  end

  it "becomes unauthentic because of invalid open orders" do
    balance = create(:balance, funded: true)
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
    }.to increase { Refund.count }.by(1)
    expect(balance.reload.authentic?).to be(true)
  end

  it "calculates total_traded correctly with order filled by multiple trades" do
    order = build(:order, :sell, give_amount: '1.5'.to_wei, take_amount: '0.9'.to_wei)
    trades = build_list(:trade, 3, order: order, amount: '0.25'.to_wei)
    total_give_amount = 0
    total_maker_receiving_amount_after_fee = 0
    total_take_amount = 0
    total_taker_receiving_amount_after_fee = 0
    trades.each do |t|
      total_give_amount += t.amount.to_i
      total_maker_receiving_amount_after_fee += t.maker_receiving_amount_after_fee.to_i
      total_take_amount += t.take_amount.to_i
      total_taker_receiving_amount_after_fee += t.taker_receiving_amount_after_fee.to_i
    end
    balance_with_sell_order = trades.first.maker_give_balance
    balance_with_buy_order = trades.first.maker_take_balance
    balance_with_sell_trade = trades.first.taker_take_balance
    balance_with_buy_trade = trades.first.taker_give_balance

    expect {
    expect {
    expect {
    expect {
      trades.each(&:save)
    }.to decrease {balance_with_sell_order.reload.total_traded}.by(total_give_amount)
    }.to increase {balance_with_buy_order.reload.total_traded}.by(total_maker_receiving_amount_after_fee)
    }.to increase {balance_with_buy_trade.reload.total_traded}.by(total_taker_receiving_amount_after_fee)
    }.to decrease {balance_with_sell_trade.reload.total_traded}.by(total_take_amount)
  end

  it 'marks balance fraud with lock' do
    balance = create(:balance)

    expect_any_instance_of(Balance).to receive(:with_lock).once do |&block|
      block.call
    end

    expect {
      balance.mark_fraud
    }.to change { balance.reload.fraud }
  end
end
