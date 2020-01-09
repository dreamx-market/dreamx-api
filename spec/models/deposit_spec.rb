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

  it 'aggregates new deposits and initializes new accounts', :focus do
    from_block_number = 7095527
    ropsten_contract_address = '0x7f6a01dcebe266779e00a4cf15e9432cb1423203'

    with_modified_env CONTRACT_ADDRESS: ropsten_contract_address do
      expect {
      expect {
        Deposit.aggregate(from_block_number)
      }.to increase { Deposit.count }.by(2)
      }.to increase { Account.count }.by(1)
    end
  end
end
