require 'test_helper'

class BroadcastTransactionJobTest < ActiveJob::TestCase
  setup do
    ENV['POSTPONE_BROADCASTING'] = 'true'
    sync_nonce
    @withdraws = batch_withdraw([
      { :account_address => '0xe37a4faa73fced0a177da51d8b62d02764f2fc45', :token_address => '0x0000000000000000000000000000000000000000', :amount => 20000000000000000, :nonce => (Time.now.to_i * 1000).to_s }
    ])
    @transaction = @withdraws.first.tx
  end

  teardown do
    ENV['POSTPONE_BROADCASTING'] = 'false'
  end

  test "update transaction after successfully broadcasting" do
    BroadcastTransactionJob.perform_now(@transaction)
    @transaction.reload
    assert_equal @transaction.status, 'unconfirmed'
    assert_not_nil @transaction.gas_limit
    assert_not_nil @transaction.gas_price
    assert_not_nil @transaction.transaction_hash
  end
end
