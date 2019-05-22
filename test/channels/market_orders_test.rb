require 'test_helper'
 
class MarketOrdersTest < ActiveJob::TestCase
  include ActionCable::TestHelper

  setup do
    @order = orders(:one)

    deposits = [
      { :account_address => @order.account_address, :token_address => @order.give_token_address, :amount => @order.give_amount }
    ]
    batch_deposit(deposits)
  end

  test "broadcast message on order creation" do
    order = Order.new(generate_order(@order))
    
    assert_broadcasts("market_orders:#{order.market.symbol}", 1) do
      order.save
    end
  end
end