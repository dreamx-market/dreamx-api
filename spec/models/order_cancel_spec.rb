require 'rails_helper'

RSpec.describe OrderCancel, type: :model do
  let (:order_cancel) { build(:order_cancel) }

  it 'must belong to an existing order' do
    order_cancel.order_hash = 'INVALID'
    expect(order_cancel.valid?).to eq(false)
    expect(order_cancel.errors.messages[:order]).to include('must exist')
  end

  it 'must belong to an open order' do
    order_cancel.order.status = 'closed'
    expect(order_cancel.valid?).to eq(false)
    expect(order_cancel.errors.messages[:order]).to include('must be open')
  end

  it 'must be the owner of the order' do
    order_cancel.order.account_address = 'SOMEONE_ELSE'
    expect(order_cancel.valid?).to eq(false)
    expect(order_cancel.errors.messages[:account]).to include('must be owner')
  end

  it 'has a unique nonce' do
    order_cancel = create(:order_cancel)
    new_order_cancel = build(:order_cancel)
    new_order_cancel.nonce = order_cancel.nonce
    expect(new_order_cancel.valid?).to eq(false)
    expect(new_order_cancel.errors.messages[:nonce]).to include('has already been taken')
  end

  it 'has a valid cancel_hash' do
    order_cancel.cancel_hash = 'INVALID'
    expect(order_cancel.valid?).to eq(false)
    expect(order_cancel.errors.messages[:cancel_hash]).to include('is invalid')
  end

  it 'has a valid signature' do
    order_cancel.signature = 'INVALID'
    expect(order_cancel.valid?).to eq(false)
    expect(order_cancel.errors.messages[:signature]).to include('is invalid')
  end

  it 'displays validation errors for the associated order' do
    order_cancel.order.signature = 'INVALID'
    expect(order_cancel.valid?).to eq(false)
    expect(order_cancel.errors.messages[:order]).to include('signature is invalid')
  end
end
