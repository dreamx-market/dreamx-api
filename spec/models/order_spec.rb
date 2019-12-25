require 'rails_helper'

RSpec.describe Order, type: :model do
  let (:order) { build(:order) }
  let (:maker_minimum) { ENV['MAKER_MINIMUM_ETH_IN_WEI'].to_i }

  it "is a buy order with volume below taker minimum" do
    expect(order.remaining_volume_is_above_taker_minimum?).to be(true)
    order.filled = '0.955'.to_wei
    expect(order.remaining_volume_is_above_taker_minimum?).to be(false)
  end

  it "is a sell order with volume below taker minimum" do
    order = build(:order, :sell, take_amount: ENV['MAKER_MINIMUM_ETH_IN_WEI'].to_i / 2)
    expect(order.remaining_volume_is_above_taker_minimum?).to be(true)
    order.filled = '0.88'.to_wei
    expect(order.remaining_volume_is_above_taker_minimum?).to be(false)
  end

  it 'must have a volume above maker minimum as a buy order on create' do
    order = build(:order, :buy)
    order.give_amount = maker_minimum - 1
    expect(order.valid?).to eq(false)
    expect(order.errors.messages[:give_amount]).to include("must be greater than #{maker_minimum}")
  end

  it 'must have a volume above maker minium as a sell order on create' do
    order = build(:order, :sell)
    order.take_amount = maker_minimum - 1
    expect(order.valid?).to eq(false)
    expect(order.errors.messages[:take_amount]).to include("must be greater than #{maker_minimum}")
  end

  it 'must not be filled on create' do
    order.filled = order.give_amount.to_i / 2
    expect(order.valid?).to eq(false)
    expect(order.errors.messages[:filled]).to include('must be equal to 0')
  end

  it 'must have a non-open status on create' do
    order.status = 'closed'
    expect(order.valid?).to eq(false)
    expect(order.errors.messages[:status]).to include('must be open')
  end

  it 'must have non-zero amounts' do
    order.give_amount = 0
    order.take_amount = 0
    expect(order.valid?).to eq(false)
    expect(order.errors.messages[:give_amount]).to include('must be greater than 0')
    expect(order.errors.messages[:take_amount]).to include('must be greater than 0')
  end

  it 'must have an expiry timestamp in the future' do
    order.expiry_timestamp_in_milliseconds = 10.days.ago
    expect(order.valid?).to eq(false)
    expect(order.errors.messages[:expiry_timestamp_in_milliseconds]).to include('must be in the future')
  end

  it 'must have a unique nonce' do
    order = create(:order)
    new_order = build(:order)
    new_order.nonce = order.nonce
    expect(new_order.valid?).to eq(false)
    expect(new_order.errors.messages[:nonce]).to include('has already been taken')
  end

  it 'must belong to an existing market' do
    order.take_token_address = 'INVALID'
    expect(order.valid?).to eq(false)
    expect(order.errors.messages[:market]).to include('market does not exist')
  end

  it 'must have a valid order_hash' do
    order.order_hash = 'INVALID'
    expect(order.valid?).to eq(false)
    expect(order.errors.messages[:order_hash]).to include('is invalid')
  end

  it 'must have a valid signature' do
    order.signature = 'INVALID'
    expect(order.valid?).to eq(false)
    expect(order.errors.messages[:signature]).to include('is invalid')
  end

  it 'must be created with a sufficient balance' do
    order.give_amount = order.balance.balance.to_i * 2
    expect(order.valid?).to eq(false)
    expect(order.errors.messages[:account]).to include('insufficient balance')
  end

  it 'must have a positive filled value' do
    order.filled = -1
    expect(order.valid?).to eq(false)
    expect(order.errors.messages[:filled]).to include('must be greater than or equal to 0')
  end

  it 'must have a filled value lesser than or equal to give_amount' do
    order.filled = order.give_amount * 2
    expect(order.valid?).to eq(false)
    expect(order.errors.messages[:filled]).to include('must not exceed give_amount')
  end

  it 'must have a valid status' do
    order.status = 'INVALID'
    expect(order.valid?).to eq(false)
    expect(order.errors.messages[:status]).to include('must be open, closed or partially_filled')
  end

  it 'must belong to an active market' do
    order.market.disable
    expect(order.valid?).to eq(false)
    expect(order.errors.messages[:market]).to include('has been disabled')
  end

  it 'does not get invalidated when MAKER_MINIMUM_ETH_IN_WEI is updated' do
    order = create(:order)
    new_minimum = (order.remaining_volume * 2).to_s
    with_modified_env MAKER_MINIMUM_ETH_IN_WEI: new_minimum do
      expect(order.valid?).to eq(true)
    end
  end

  it 'belongs to a give balance and a take balance' do
    expect(order.give_balance).to_not be_nil
    expect(order.take_balance).to_not be_nil
  end

  it 'holds balance with locks' do
    allow(order.balance).to receive(:with_lock).and_call_original

    order.hold_balance_with_lock

    expect(order.balance).to have_received(:with_lock).once
  end
end
