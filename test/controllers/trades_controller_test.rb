require 'test_helper'

class TradesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @OLD_CONTRACT_ADDRESS = ENV['CONTRACT_ADDRESS']
    @OLD_FEE_COLLECTOR_ADDRESS = ENV['FEE_COLLECTOR_ADDRESS']
    @OLD_MAKER_FEE_PERCENTAGE = ENV['MAKER_FEE_PERCENTAGE']
    @OLD_TAKER_FEE_PERCENTAGE = ENV['TAKER_FEE_PERCENTAGE']
    ENV['CONTRACT_ADDRESS'] = '0x4ef6474f40bf5c9dbc013efaac07c4d0cb17219a'
    ENV['FEE_COLLECTOR_ADDRESS'] = '0xcc6cfe1a7f27f84309697beeccbc8112a6b7240a'
    ENV['MAKER_FEE_PERCENTAGE'] = '0.1'
    ENV['TAKER_FEE_PERCENTAGE'] = '0.2'

    @trade = trades(:one)

    @order = orders(:one)
    uncreate_order(@order)
    assert_difference("Order.count") do
      post orders_url, params: { order: { account_address: @order.account_address, expiry_timestamp_in_milliseconds: @order.expiry_timestamp_in_milliseconds, give_amount: @order.give_amount, give_token_address: @order.give_token_address, nonce: @order.nonce, order_hash: @order.order_hash, signature: @order.signature, take_amount: @order.take_amount, take_token_address: @order.take_token_address } }, as: :json
    end

    @maker_address = @trade.order.account_address
    @taker_address = @trade.account_address
    @fee_address = ENV['FEE_COLLECTOR_ADDRESS']
    @give_token_address = @trade.order.give_token_address
    @take_token_address = @trade.order.take_token_address
  end

  teardown do
    ENV['CONTRACT_ADDRESS'] = @OLD_CONTRACT_ADDRESS
    ENV['FEE_COLLECTOR_ADDRESS'] = @OLD_FEE_COLLECTOR_ADDRESS
    ENV['MAKER_FEE_PERCENTAGE'] = @OLD_MAKER_FEE_PERCENTAGE
    ENV['TAKER_FEE_PERCENTAGE'] = @OLD_TAKER_FEE_PERCENTAGE
  end

  # test "should get index" do
  #   get trades_url, as: :json
  #   assert_response :success
  # end

  test "should create trade, collect fees and swap balances" do
    @trade.destroy

    before_trade_balances = [
      { :account_address => @maker_address, :token_address => @give_token_address, :balance => 0, :hold_balance => 100000000000000000000 },
      { :account_address => @maker_address, :token_address => @take_token_address, :balance => 0, :hold_balance => 0 },
      { :account_address => @taker_address, :token_address => @give_token_address, :balance => 0, :hold_balance => 0 },
      { :account_address => @taker_address, :token_address => @take_token_address, :balance => 100000000000000000000, :hold_balance => 0 },
      { :account_address => @fee_address, :token_address => @take_token_address, :balance => 0, :hold_balance => 0 },
      { :account_address => @fee_address, :token_address => @give_token_address, :balance => 0, :hold_balance => 0 }
    ]
    after_trade_balances = [
      { :account_address => @maker_address, :token_address => @give_token_address, :balance => 0, :hold_balance => 0 },
      { :account_address => @maker_address, :token_address => @take_token_address, :balance => 499500000000000000, :hold_balance => 0 },
      { :account_address => @taker_address, :token_address => @give_token_address, :balance => 99800000000000000000, :hold_balance => 0 },
      { :account_address => @taker_address, :token_address => @take_token_address, :balance => 99500000000000000000, :hold_balance => 0 },
      { :account_address => @fee_address, :token_address => @give_token_address, :balance => 200000000000000000, :hold_balance => 0 },
      { :account_address => @fee_address, :token_address => @take_token_address, :balance => 500000000000000, :hold_balance => 0 }
    ]
    before_trade_orders = [
      { :order_hash => @order.order_hash, :filled => 0, :status => "open" }
    ]
    after_trade_orders = [
      { :order_hash => @order.order_hash, :filled => 100000000000000000000, :status => "closed" }
    ]
    after_trade_trades = [
      { :trade_hash => @trade.trade_hash }
    ]

    assert_model(Balance, before_trade_balances)
    assert_model(Order, before_trade_orders)
    assert_model_nil(Trade, after_trade_trades)

    assert_difference('Trade.count') do
      post trades_url, params: { trade: { account_address: @trade.account_address, amount: @trade.amount, nonce: @trade.nonce, order_hash: @trade.order_hash, signature: @trade.signature, trade_hash: @trade.trade_hash, uuid: @trade.uuid } }, as: :json
    end

    assert_response 201

    assert_model(Balance, after_trade_balances)
    assert_model(Order, after_trade_orders)
    assert_model(Trade, after_trade_trades)
  end

  # test "should show trade" do
  #   get trade_url(@trade), as: :json
  #   assert_response :success
  # end

  # test "should update trade" do
  #   patch trade_url(@trade), params: { trade: { account_address: @trade.account_address, amount: @trade.amount, nonce: @trade.nonce, order_hash: @trade.order_hash, signature: @trade.signature, trade_hash: @trade.trade_hash, uuid: @trade.uuid } }, as: :json
  #   assert_response 200
  # end

  # test "should destroy trade" do
  #   assert_difference('Trade.count', -1) do
  #     delete trade_url(@trade), as: :json
  #   end

  #   assert_response 204
  # end
end
