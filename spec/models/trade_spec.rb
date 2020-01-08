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

    expect {
      new_trade.save(validate: false)
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it 'must have a unique trade_hash' do
    trade = create(:trade)
    new_trade = build(:trade)
    new_trade.trade_hash = trade.trade_hash

    expect {
      new_trade.save(validate: false)
    }.to raise_error(ActiveRecord::RecordNotUnique)
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

  it 'is initialized with attributes' do
    expect(trade.market).to_not be_nil
    expect(trade.sell).to_not be_nil
    expect(trade.price).to_not be_nil
    expect(trade.give_balance).to_not be_nil
    expect(trade.take_balance).to_not be_nil
    expect(trade.take_amount).to_not be_nil
  end
end
