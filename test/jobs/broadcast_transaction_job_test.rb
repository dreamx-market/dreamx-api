require 'test_helper'

class BroadcastTransactionJobTest < ActiveJob::TestCase
  setup do
    ENV['POSTPONE_BROADCASTING'] = 'true'
    sync_nonce
    @withdraws = batch_withdraw([
      { :account_address => accounts[0], :token_address => '0x0000000000000000000000000000000000000000', :amount => 20000000000000000, :nonce => (Time.now.to_i * 1000).to_s }
    ])
    @orders = batch_order([
      { :account_address => accounts[0], :give_token_address => '0x75d417ab3031d592a781e666ee7bfc3381ad33d5', :give_amount => 1000000000000000000, :take_token_address => '0x0000000000000000000000000000000000000000', :take_amount => 1000000000000000000 }
    ])
    # @trades = batch_trade([
    #   { :account_address => @trade.account_address, :order_hash => @orders[0].order_hash, :amount => @trade.amount }
    # ])
  end

  teardown do
    ENV['POSTPONE_BROADCASTING'] = 'false'
  end

  # test "broadcast and update a withdraw transaction" do
  #   transaction = @withdraws.first.tx
  #   BroadcastTransactionJob.perform_now(transaction)
  #   transaction.reload
  #   assert_equal transaction.status, 'unconfirmed'
  #   assert_not_nil transaction.gas_limit
  #   assert_not_nil transaction.gas_price
  #   assert_not_nil transaction.transaction_hash
  # end

  test "broadcast and update a trade transaction" do
    p @withdraws.length, @orders.length
  end
end
