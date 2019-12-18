require 'test_helper'
 
class AccountBalancesTest < ActionCable::TestCase
  include ActiveJob::TestHelper

  setup do
    @deposit = deposits(:one)
    @withdraw = withdraws(:one)
    @order = orders(:one)
    @order_cancel = order_cancels(:one)
    @trade = trades(:one)

    deposit_data = [
      { :account_address => @withdraw.account_address, :token_address => @withdraw.token_address, :amount => @withdraw.amount },
      { :account_address => @order.account_address, :token_address => @order.give_token_address, :amount => @order.give_amount },
      { :account_address => @order.account_address, :token_address => @order.give_token_address, :amount => @order.give_amount },
      { :account_address => @trade.account_address, :token_address => @order.take_token_address, :amount => @order.take_amount }
    ]
    batch_deposit(deposit_data)

    order_data = [
      { :account_address => @order.account_address, :give_token_address => @order.give_token_address, :give_amount => @order.give_amount, :take_token_address => @order.take_token_address, :take_amount => @order.take_amount }
    ]
    @orders = batch_order(order_data)
  end

  test "broadcast a message when a new order is created" do
    new_order = Order.new(generate_order(@order))

    assert_broadcasts("account_balances:#{new_order.account_address}", 1) do
      perform_enqueued_jobs do
        new_order.save
      end
    end
  end

  test "broadcast a message when an order is cancelled" do
    @order_cancel.order_hash = @orders[0].order_hash
    @order_cancel.account_address = @orders[0].account_address
    new_order_cancel = OrderCancel.new(generate_order_cancel(@order_cancel))

    assert_broadcasts("account_balances:#{new_order_cancel.account_address}", 1) do
      perform_enqueued_jobs do
        new_order_cancel.save
      end
    end
  end

  test "broadcast a message when a new trade is created" do
    new_trade = Trade.new(generate_trade({ :account_address => @trade.account_address, :order_hash => @orders[0].order_hash, :amount => @trade.amount }))

    assert_broadcasts("account_balances:#{new_trade.account_address}", 2) do
      perform_enqueued_jobs do
        new_trade.save
      end
    end
  end
end