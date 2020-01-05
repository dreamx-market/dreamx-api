require 'rails_helper'

RSpec.describe OrderCancel, type: :model do
  let (:order_cancel) { build(:order_cancel) }

  it 'must belong to an existing order' do
    order_cancel.order_hash = 'INVALID'
    expect(order_cancel.valid?).to eq(false)
    expect(order_cancel.errors.messages[:order]).to include('must exist')
  end

  it 'can only cancel open orders' do
    order = order_cancel.order
    order.update(status: 'closed')
    expect(order_cancel.valid?).to eq(false)
    expect(order_cancel.errors.messages[:order]).to include('must be open')
  end

  it 'must be the owner of the order' do
    order = order_cancel.order
    order.account_address = 'invalid'
    order.save(validate: false)
    expect(order_cancel.valid?).to eq(false)
    expect(order_cancel.errors.messages[:account]).to include('must be owner')
  end

  it 'has a unique nonce' do
    order_cancel = create(:order_cancel)
    new_order_cancel = build(:order_cancel)
    new_order_cancel.nonce = order_cancel.nonce

    expect {
      new_order_cancel.save(validate: false)
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it 'has a unique cancel_hash' do
    order_cancel = create(:order_cancel)
    new_order_cancel = build(:order_cancel)
    new_order_cancel.cancel_hash = order_cancel.cancel_hash
    
    expect {
      new_order_cancel.save(validate: false) # uniqueness validations must be tested at the database level
    }.to raise_error(ActiveRecord::RecordNotUnique)
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

  it 'belongs to a balance' do
    expect(order_cancel.balance).to_not be_nil
  end
end
