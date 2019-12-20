require 'rails_helper'

RSpec.describe Deposit, type: :model do
  let (:built_deposit) { build(:deposit) }
  let (:deposit) {create(:deposit)}

  it "transaction_hash must be unique" do
    new_deposit = build(:deposit, transaction_hash: deposit.transaction_hash)
    expect(new_deposit).to_not be_valid
    expect(new_deposit.errors.messages[:transaction_hash]).to include("has already been taken")
  end

  it "has a transaction_hash" do
    built_deposit.transaction_hash = nil
    expect(built_deposit).to_not be_valid
    expect(built_deposit.errors.messages[:transaction_hash]).to include("can't be blank")
  end
end
