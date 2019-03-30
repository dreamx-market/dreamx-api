require 'test_helper'

class BroadcastTransactionJobTest < ActiveJob::TestCase
  setup do
    @transaction = transactions(:one)
  end

  test "update transaction after successfully broadcasting" do
    BroadcastTransactionJob.perform_now(@transaction)
    @transaction.reload
    assert_equal @transaction.status, 'pending'
    assert_not_nil @transaction.gas_limit
    assert_not_nil @transaction.gas_price
    assert_not_nil @transaction.transaction_hash
    assert_not_nil @transaction.nonce
    assert_not_nil @transaction.fee
  end
end
