require 'rails_helper'

RSpec.describe Transaction, type: :model do
  let (:transaction) { build(:withdraw).tx }

  it 'expires', :onchain do
    transaction = create(:withdraw).tx
    transaction.update({ broadcasted_at: 10.minutes.ago })
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

    expect {
      Transaction.confirm_mined_transactions
    }.to change { transaction.reload.status }.to('confirmed')
  end

  it 'detects a replaced transaction and regenerates' do
    last_confirmed_nonce = get_last_confirmed_nonce
    transaction = build(:withdraw).tx
    transaction.nonce = last_confirmed_nonce
    transaction.save

    expect {
      Transaction.confirm_mined_transactions
      expect(Config.get('read_only')).to eq('true')
    }.to change { transaction.reload.status }.to('replaced')

    expect {
    expect {
      Transaction.regenerate_replaced_transactions
      expect(Config.get('read_only')).to eq('false')
      transaction.reload
    }.to change { transaction.status }.to('pending')
    }.to change { transaction.nonce }
  end

  it 'doesnt regenerate replaced transactions if there are still unconfirmed transactions' do
    replaced_transaction = create(:withdraw, transaction_status: 'replaced').tx
    unconfirmed_transaction = create(:withdraw, transaction_status: 'unconfirmed').tx

    expect {
      Transaction.regenerate_replaced_transactions
    }.to_not change { replaced_transaction.reload.status }
  end

  skip 'detects a failed transaction and refunds with lock', :onchain do
    withdraw = build(:withdraw)
    withdraw.signature = 'INVALID'
    withdraw.save(validate: false)
    BroadcastTransactionJob.perform_now(withdraw.tx)

    expect_any_instance_of(Balance).to receive(:with_lock).once do |&block|
      block.call
    end

    expect {
    expect {
    expect {
      Transaction.confirm_mined_transactions
      withdraw.reload
      pp withdraw.tx.status
    }.to change { withdraw.tx.status }.to('failed')
    }.to increase { withdraw.balance.balance }.by(withdraw.amount)
    }.to increase { Refund.count }.by(1)
  end

  it 'detacts an out of gas transaction', :onchain do
    with_modified_env GAS_LIMIT: '30000' do
      transaction = create(:withdraw).tx

      begin
        BroadcastTransactionJob.perform_now(transaction)
      rescue IOError => err
        expect(err.message).to eq('VM Exception while processing transaction: out of gas')
      end

      expect {
        Transaction.confirm_mined_transactions
      }.to change { transaction.reload.status }.to('out_of_gas')
    end
  end

  it 'has a hash prior to broadcasting' do
    transaction = create(:withdraw).tx
    expect(transaction.transaction_hash).to_not be_nil
  end
end
