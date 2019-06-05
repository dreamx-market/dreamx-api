require 'test_helper'
 
class AccountTradesTest < ActionCable::TestCase
  include ActiveJob::TestHelper

  setup do
    sync_nonce
    @trade = trades(:one)
    @order = orders(:one)
    @deposits = batch_deposit([
      { :account_address => @trade.account_address, :token_address => @order.take_token_address, :amount => @order.take_amount },
      { :account_address => @order.account_address, :token_address => @order.give_token_address, :amount => @order.give_amount }
    ])
    @orders = batch_order([
      { :account_address => @order.account_address, :give_token_address => @order.give_token_address, :give_amount => @order.give_amount, :take_token_address => @order.take_token_address, :take_amount => @order.take_amount }
    ])
    @maker_address = @order.account_address
    @taker_address = @trade.account_address
  end

  test "broadcast a message for both maker and taker when a new trade is created" do
    trade = Trade.new(generate_trade({ :account_address => @trade.account_address, :order_hash => @orders[0].order_hash, :amount => @trade.amount }))
    
    assert_broadcasts("account_trades:#{@maker_address}", 1) do
      assert_broadcasts("account_trades:#{@taker_address}", 1) do
        perform_enqueued_jobs do
          trade.save
        end
      end
    end
  end

  test "broadcast a message for both maker and taker when a trade's transaction is broadcasted" do
    order = batch_order([
      { :account_address => addresses[0], :give_token_address => '0x75d417ab3031d592a781e666ee7bfc3381ad33d5', :give_amount => 1000000000000000000, :take_token_address => '0x0000000000000000000000000000000000000000', :take_amount => 1000000000000000000 }
    ]).first
    trade = batch_trade([
      { :account_address => addresses[1], :order_hash => order.order_hash, :amount => 1000000000000000000 }
    ]).first

    assert_broadcasts("account_trades:#{order.account_address}", 1) do
      assert_broadcasts("account_trades:#{trade.account_address}", 1) do
        perform_enqueued_jobs do
          BroadcastTransactionJob.perform_now(trade.tx)
        end
      end
    end
  end
end