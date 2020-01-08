require 'rails_helper'

RSpec.describe Withdraw, type: :model do
  let (:withdraw) { build(:withdraw) }

  it 'must belong to an existing account' do
    withdraw.account_address = 'invalid'
    expect(withdraw.valid?).to eq(false)
    expect(withdraw.errors.messages[:account]).to include('must exist')
  end

  it 'must has a valid token_address' do
    withdraw.token_address = 'invalid'
    expect(withdraw.valid?).to eq(false)
    expect(withdraw.errors.messages[:token]).to include('must exist')
  end

  it 'must have a unique nonce' do
    withdraw1 = create(:withdraw)
    withdraw2 = build(:withdraw)
    withdraw2.nonce = withdraw1.nonce

    expect {
      withdraw2.save(validate: false)
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it 'must be created by an account with sufficient balance' do
    withdraw.balance.update({ balance: 0 })
    expect(withdraw.valid?).to eq(false)
    expect(withdraw.errors.messages[:account]).to include('has insufficient balance')
  end

  it 'must have an amount above minimum' do
    minimum = withdraw.token.withdraw_minimum.to_i
    withdraw.amount = minimum - 1
    expect(withdraw.valid?).to eq(false)
    expect(withdraw.errors.messages[:amount]).to include("must be greater than #{minimum}")
  end

  it 'must have a valid hash' do
    withdraw.withdraw_hash = 'invalid'
    expect(withdraw.valid?).to eq(false)
    expect(withdraw.errors.messages[:withdraw_hash]).to include('is invalid')
  end

  it 'it has a unique withdraw_hash' do
    withdraw1 = create(:withdraw)
    withdraw2 = build(:withdraw)
    withdraw2.withdraw_hash = withdraw1.withdraw_hash

    expect {
      withdraw2.save(validate: false)
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it 'must have a valid signature' do
    withdraw.signature = 'invalid'
    expect(withdraw.valid?).to eq(false)
    expect(withdraw.errors.messages[:signature]).to include('is invalid')
  end

  it 'is initialized with a transaction' do
    expect(withdraw.tx).to_not be_nil
  end

  it 'must not belong to an ejected account' do
    withdraw.account.eject
    expect(withdraw.valid?).to eq(false)
    expect(withdraw.errors.messages[:account]).to include('has been ejected')
  end

  it 'debits balance after created' do
    balance = withdraw.balance

    expect {
      withdraw.save
    }.to decrease { balance.reload.balance }.by(withdraw.amount)
  end

  it 'calculates withdrawal fee' do
    withdraw.token.update({ withdraw_fee: '0.03'.to_wei })
    withdraw.amount = '1'.to_wei
    expect(withdraw.calculate_fee.to_s).to eq('0.03'.to_wei)
  end

  it 'belongs to a balance' do
    expect(withdraw.balance).to_not be_nil
  end
end
