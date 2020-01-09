require 'rails_helper'

RSpec.describe Transaction, type: :model do
  let (:transaction) { build(:withdraw).tx }
  let (:client) { Ethereum::Singleton.instance }

  it 'expires', :onchain do
    transaction = create(:withdraw).tx
    transaction.broadcasted_at = 10.minutes.ago
    expect(transaction.reload.expired?).to eq(true)
  end

  it 'cannot expire if has been confirmed', :onchain do
    transaction = create(:withdraw).tx
    transaction.update({ status: 'confirmed', broadcasted_at: 10.minutes.ago })
    expect(transaction.reload.expired?).to eq(false)
  end

  skip 'confirms successful transactions' do
    from_block_number = 7095527
    ropsten_contract_address = '0x7f6a01dcebe266779e00a4cf15e9432cb1423203'
    ropsten_transaction_hash = '0x624c55566e2e3f88e73cb351e6a0f93d0c12bb2ace175a8e073b342c3887ff85'

    transaction = create(:withdraw).tx
    transaction.update(transaction_hash: ropsten_transaction_hash)

    with_modified_env CONTRACT_ADDRESS: ropsten_contract_address do
      expect {
        Transaction.confirm_mined_transactions(from_block_number)
      }.to change { transaction.reload.status }.to('confirmed')
    end
  end

  it 'has a hash prior to broadcasting' do
    transaction = create(:withdraw).tx
    expect(transaction.transaction_hash).to_not be_nil
  end
end
