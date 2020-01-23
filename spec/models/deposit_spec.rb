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

  it 'belongs to a balance' do
    expect(deposit.balance).to_not be_nil
  end

  it "aggregates new deposits" do
    allow(Etherscan).to receive(:send_request).and_return(etherscan_deposits)

    expect {
    expect {
      from = 7095527
      Deposit.aggregate(from)
    }.to increase { Deposit.count }.by(2)
    }.to increase { Account.count }.by(1)
  end

  it "cannot belong to an ejected account" do
    deposit.account.eject
    expect(deposit.valid?).to eq(false)
    expect(deposit.errors.messages[:account]).to include('has been ejected')
  end
end
