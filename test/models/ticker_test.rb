require 'test_helper'

class TickerTest < ActiveSupport::TestCase
  setup do
    @ticker = tickers(:one)
    @token_one = tokens(:one)
    @token_three = tokens(:four)
    @trade = trades(:one)
    @order = orders(:one)
    @order_cancel = order_cancels(:one)
    @deposits = batch_deposit([
      { :account_address => @trade.account_address, :token_address => @order.take_token_address, :amount => @trade.amount },
      { :account_address => @order.account_address, :token_address => @order.give_token_address, :amount => @order.give_amount }
    ])
  end

  test "automatically created on market creations" do
    market = Market.create({ :base_token_address => @token_one.address, :quote_token_address => "0x7cca38cdd9a1dde0750fb3825c7e4d2395f25259" })
    assert_not_nil Ticker.find_by({ :market_symbol => market.symbol })
  end

  test "should update on new trades" do
    order = Order.create(generate_order(@order))
    trade = Trade.create(generate_trade({ :account_address => @trade.account_address, :order_hash => order.order_hash, :amount => @trade.amount }))

    assert_changes "@ticker.last" do
      @ticker.reload
    end
  end

  test "should update on new orders and order cancels" do
    order = Order.create(generate_order(@order))

    assert_changes "@ticker.lowest_ask" do
      @ticker.reload
    end

    @order_cancel.order_hash, @order_cancel.account_address = order.order_hash, order.account_address
    order_cancel = OrderCancel.create(generate_order_cancel(@order_cancel))

    assert_changes "@ticker.lowest_ask" do
      @ticker.reload
    end
  end
end
