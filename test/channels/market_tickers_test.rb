require 'test_helper'
 
class MarketTickersTest < ActionCable::TestCase
  include ActiveJob::TestHelper
  
  setup do
    @trade = trades(:one)
    @order = orders(:one)
    @order_cancel = order_cancels(:one)
    batch_deposit([
      { :account_address => @trade.account_address, :token_address => @order.take_token_address, :amount => @trade.amount },
      { :account_address => @order.account_address, :token_address => @order.give_token_address, :amount => @order.give_amount }
    ])
  end

  test "broadcast a message when ticker data has been changed by a trade" do
    order = Order.create(generate_order(@order))
    trade = Trade.new(generate_trade({ :account_address => @trade.account_address, :order_hash => order.order_hash, :amount => @trade.amount }))
    trade.market.ticker.update_data

    assert_broadcasts("market_tickers:#{trade.market_symbol}", 1) do
      perform_enqueued_jobs do
        trade.save
      end
    end
  end

  test "broadcast a message when ticker data has been changed by an order creation or cancellation" do
    order = Order.new(generate_order(@order))
    order.market.ticker.update_data

    assert_broadcasts("market_tickers:#{order.market_symbol}", 1) do
      perform_enqueued_jobs do
        order.save
      end
    end

    @order_cancel.order_hash = order.order_hash
    @order_cancel.account_address = order.account_address
    new_order_cancel = OrderCancel.new(generate_order_cancel(@order_cancel))

    assert_broadcasts("market_tickers:#{new_order_cancel.market_symbol}", 1) do
      perform_enqueued_jobs do
        new_order_cancel.save
      end
    end
  end
end