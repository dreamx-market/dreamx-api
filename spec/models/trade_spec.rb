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

    expect(Balance).to have_received(:lock).once
  end

  it 'fills order with locks' do
    allow(trade.order).to receive(:with_lock).and_call_original

    trade.fill_order_with_lock

    expect(trade.order).to have_received(:with_lock).once
  end

  it 'belongs to a balance' do
    expect(trade.balance).to_not be_nil
  end
end
