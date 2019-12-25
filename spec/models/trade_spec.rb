require 'rails_helper'

RSpec.describe Trade, type: :model do
  let (:trade) { build(:trade) }

  it 'must be created by an account with a sufficient balance' do
    trade.balance.update({ balance: 0 })
    expect(trade.valid?).to eq(false)
    expect(trade.errors.messages[:balance]).to include('is insufficient')
  end

  it 'must have a unique nonce' do
    trade = create(:trade)
    new_trade = build(:trade)
    new_trade.nonce = trade.nonce
    expect(new_trade.valid?).to eq(false)
    expect(new_trade.errors.messages[:nonce]).to include('has already been taken')
  end

  it 'must belong to a valid order' do
    trade.order_hash = 'INVALID'
    expect(trade.valid?).to eq(false)
    expect(trade.errors.messages[:order]).to include('must exist')
  end

  it 'must have a valid hash' do
    trade.trade_hash = 'INVALID'
    expect(trade.valid?).to eq(false)
    expect(trade.errors.messages[:trade_hash]).to include('is invalid')
  end

  it 'must have a valid signature' do
    trade.trade_hash = 'INVALID'
    expect(trade.valid?).to eq(false)
    expect(trade.errors.messages[:trade_hash]).to include('is invalid')
  end

  it 'must have a volume above taker minimum' do
    taker_minimum = ENV['TAKER_MINIMUM_ETH_IN_WEI'].to_i
    trade.amount = trade.amount.to_i / 10
    expect(trade.valid?).to eq(false)
    expect(trade.errors.messages[:amount]).to include("must be greater than #{taker_minimum}")
  end

  it 'must execute an open order' do
    trade.order.cancel
    expect(trade.valid?).to eq(false)
    expect(trade.errors.messages[:order]).to include('must be open')
  end

  it 'must execute an order with sufficient remaining volume' do
    trade.amount = trade.order.give_amount.to_i + 1
    expect(trade.valid?).to eq(false)
    expect(trade.errors.messages[:order]).to include('must have sufficient volume')
  end

  it 'trades balances with locks' do
    allow(Balance).to receive(:lock).and_call_original
    
    trade.trade_balances_with_lock

    expect(Balance).to have_received(:lock).twice # 1 for trading the balances, 1 for saving the order
  end

  it 'fills order with locks' do
    allow(trade.order).to receive(:with_lock).and_call_original

    trade.fill_order_with_lock

    expect(trade.order).to have_received(:with_lock).once
  end

  it 'belongs to a give balance and a take balance' do
    expect(trade.give_balance).to_not be_nil
    expect(trade.take_balance).to_not be_nil
  end

  it 'refunds a partial trade with locks, should not refund the entire order' do
    trade = create(:trade, :partial)
    trade.reload
    allow(Balance).to receive(:lock).and_call_original

    expect {
    expect {
    expect {
      trade.refund
      trade.reload
    }.to increase { trade.taker_balance.balance }.by(trade.take_amount)
    }.to increase { trade.maker_balance.balance }.by(trade.give_amount)
    }.to increase { Refund.count }.by(2)

    expect(Balance).to have_received(:lock).once
  end

  it 'cannot refund if unpersisted' do
    expect {
      trade.refund
    }.to raise_error('cannot refund unpersisted trades')
  end

  it 'if trading amount is greater than onchain balance, refunds only the onchain balance' do
    trade = create(:trade)
    onchain_balance = trade.take_amount.to_i / 2
    allow(trade.balance).to receive(:onchain_balance).and_return(onchain_balance)

    trade.refund
    
    expect(Refund.last.amount.to_i).to eq(onchain_balance)
  end
end
