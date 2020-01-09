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

  it 'confirms successful transactions' do
    from_block_number = 7090218
    ropsten_server_private_key = '0x667808D292681DA47E70DF33EF276264DF39A056DE95427CFB9437106A08FAF3'
    ropsten_transaction_hash = '0x7eb384a190f305b8f08c80bb1d90667e338f206b42415274ad9a013a172fad74'

    transaction = create(:withdraw).tx
    transaction.update(transaction_hash: ropsten_transaction_hash)

    with_modified_env SERVER_PRIVATE_KEY: ropsten_server_private_key do
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
