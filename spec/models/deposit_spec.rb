require 'rails_helper'

RSpec.describe Deposit, type: :model do
  let (:deposit) { build(:deposit) }

  it "must have a unique transaction_hash" do
    deposit = create(:deposit)
    new_deposit = build(:deposit, transaction_hash: deposit.transaction_hash)
    expect(new_deposit).to_not be_valid
    expect(new_deposit.errors.messages[:transaction_hash]).to include("has already been taken")
  end

  it "must have a transaction_hash" do
    deposit.transaction_hash = nil
    expect(deposit).to_not be_valid
    expect(deposit.errors.messages[:transaction_hash]).to include("can't be blank")
  end

  it 'aggregates new deposits', :onchain do
    token_address = token_addresses['ETH']
    amount = '1'.to_wei
    account_address = addresses[0]
    tx = create_onchain_deposit(token_address, amount, account_address)
    block_number = tx[:block_number].hex

    expect {
      Deposit.aggregate(block_number)
    }.to have_increased { Deposit.count }.by(1)
  end

  it 'must belong to an existing account' do
    deposit.account_address = 'INVALID'
    expect(deposit).to_not be_valid
    expect(deposit.errors.messages[:account]).to include("must exist")
  end

  it 'must belong to an existing token' do
    deposit.token_address = 'INVALID'
    expect(deposit).to_not be_valid
    expect(deposit.errors.messages[:token]).to include("must exist")
  end

  it 'must have a non-zero amount' do
    deposit.amount = 0
    expect(deposit).to_not be_valid
    expect(deposit.errors.messages[:amount]).to include('must be greater than 0')
  end

  it 'credits balance with pessimistic lock after created' do
    balance = deposit.balance

    expect_any_instance_of(Balance).to receive(:with_lock).once do |&block|
      block.call
    end

    expect {
      deposit.save
    }.to have_increased { balance.reload.balance }.by(deposit.amount)
  end
end
