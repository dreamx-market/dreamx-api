require 'test_helper'
 
class MarketTickersTest < ActionCable::TestCase
  include ActiveJob::TestHelper
  
  setup do
    @trade = trades(:one)
    @order = orders(:one)
    @order_cancel = order_cancels(:one)
    @deposits = batch_deposit([
      { :account_address => @trade.account_address, :token_address => @order.take_token_address, :amount => @trade.amount },
      { :account_address => @order.account_address, :token_address => @order.give_token_address, :amount => @order.give_amount }
    ])
  end

  # test "broadcast a message when a new trade is created" do
  #   trade = Trade.new(generate_trade({ :account_address => @trade.account_address, :order_hash => @orders[0].order_hash, :amount => @trade.amount }))
    
  #   assert_broadcasts("market_trades:#{trade.market_symbol}", 1) do
  #     perform_enqueued_jobs do
  #       trade.save
  #     end
  #   end
  # end

  test "broadcast a message when ticker data has been changed by a trade" do
  end

  # test "broadcast a message when ticker data has been changed by an order" do
  # end

  # test "broadcast a message when ticker data has been changed by a cancelled order" do
  # end
end