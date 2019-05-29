require 'test_helper'
 
class MarketOrdersTest < ActionCable::TestCase
  include ActiveJob::TestHelper
  
  setup do
    @order = orders(:one)
    @trade = trades(:one)
    @order_cancel = order_cancels(:one)
    batch_deposit([
      { :account_address => @trade.account_address, :token_address => @order.take_token_address, :amount => @trade.amount },
      { :account_address => @order.account_address, :token_address => @order.give_token_address, :amount => @order.give_amount }
    ])
  end

  test "broadcasts a message when a new order is created or filled" do
    order = Order.new(generate_order(@order))
    assert_broadcasts("market_orders:#{order.market_symbol}", 1) do
      perform_enqueued_jobs do
        order.save
      end
    end

    trade = Trade.new(generate_trade({ :account_address => @trade.account_address, :order_hash => order.order_hash, :amount => @trade.amount }))
    assert_broadcasts("market_orders:#{order.market_symbol}", 1) do
      perform_enqueued_jobs do
        trade.save
      end
    end
  end

  test "broadcasts a message when an order is cancelled" do
    order = Order.new(generate_order(@order))
    assert_broadcasts("market_orders:#{order.market_symbol}", 1) do
      perform_enqueued_jobs do
        order.save
      end
    end

    @order_cancel.order_hash = order.order_hash
    @order_cancel.account_address = order.account_address
    new_order_cancel = OrderCancel.new(generate_order_cancel(@order_cancel))
    assert_broadcasts("market_orders:#{order.market_symbol}", 1) do
      perform_enqueued_jobs do
        new_order_cancel.save
      end
    end
  end
end