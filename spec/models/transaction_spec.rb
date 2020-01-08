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

  it 'confirms successful transactions', :onchain do
    transaction = create(:withdraw).tx
    BroadcastTransactionJob.perform_now(transaction)
    block = client.eth_get_block_by_number('latest', false).convert_keys_to_underscore_symbols![:result]

    expect {
      Transaction.confirm_mined_transactions(block)
    }.to change { transaction.reload.status }.to('confirmed')
  end

  it 'has a hash prior to broadcasting' do
    transaction = create(:withdraw).tx
    expect(transaction.transaction_hash).to_not be_nil
  end
end
