require 'test_helper'

class BroadcastTransactionJobTest < ActiveJob::TestCase
  setup do
    sync_nonce
  end

  test "broadcast and update a withdraw transaction" do
    withdraw = batch_withdraw([
      { :account_address => accounts[0], :token_address => '0x0000000000000000000000000000000000000000', :amount => 20000000000000000, :nonce => (Time.now.to_i * 1000).to_s }
    ]).first
    transaction = withdraw.tx
    BroadcastTransactionJob.perform_now(withdraw.tx)
    transaction.reload
    assert_equal transaction.status, 'unconfirmed'
    assert_not_nil transaction.gas_limit
    assert_not_nil transaction.gas_price
    assert_not_nil transaction.transaction_hash
  end

  test "broadcast and update a trade transaction" do
    order = batch_order([
      { :account_address => accounts[0], :give_token_address => '0x75d417ab3031d592a781e666ee7bfc3381ad33d5', :give_amount => 1000000000000000000, :take_token_address => '0x0000000000000000000000000000000000000000', :take_amount => 1000000000000000000 }
    ]).first
    trade = batch_trade([
      { :account_address => accounts[1], :order_hash => order.order_hash, :amount => 1000000000000000000 }
    ]).first
    transaction = trade.tx
    BroadcastTransactionJob.perform_now(transaction)
    transaction.reload
    assert_equal transaction.status, 'unconfirmed'
    assert_not_nil transaction.gas_limit
    assert_not_nil transaction.gas_price
    assert_not_nil transaction.transaction_hash
  end

  test "should not broadcast if there has been a replaced transaction" do
    replaced_transaction = transactions(:one)
    replaced_transaction.update({ :status => 'replaced' })
  
    withdraw = batch_withdraw([
      { :account_address => accounts[0], :token_address => '0x0000000000000000000000000000000000000000', :amount => 20000000000000000, :nonce => (Time.now.to_i * 1000).to_s }
    ]).first
    transaction = withdraw.tx
    BroadcastTransactionJob.perform_now(withdraw.tx)
    transaction.reload
    assert_equal transaction.status, 'pending'
  end
end
