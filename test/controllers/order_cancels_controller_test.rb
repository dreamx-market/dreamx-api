require 'test_helper'

class OrderCancelsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @OLD_CONTRACT_ADDRESS = ENV['CONTRACT_ADDRESS']
    ENV['CONTRACT_ADDRESS'] = '0x4ef6474f40bf5c9dbc013efaac07c4d0cb17219a'

    @order_cancel = order_cancels(:one)
    @order = orders(:one)
  end

  teardown do
    ENV['CONTRACT_ADDRESS'] = @OLD_CONTRACT_ADDRESS
  end

  # test "should get index" do
  #   get order_cancels_url, as: :json
  #   assert_response :success
  # end

  test "should create order_cancel and refund" do
    @order_cancel.destroy

    before_cancel_balances = [
      { :account_address => @order_cancel.account_address, :token_address => @order_cancel.order.give_token_address, :balance => 0, :hold_balance => 100000000000000000000 }
    ]
    after_cancel_balances = [
      { :account_address => @order_cancel.account_address, :token_address => @order_cancel.order.give_token_address, :balance => 100000000000000000000, :hold_balance => 0 }
    ]
    before_cancel_orders = [
      { :order_hash => @order.order_hash, :status => "open" }
    ]
    after_cancel_orders = [
      { :order_hash => @order.order_hash, :status => "cancelled" } 
    ]

    assert_model(Balance, before_cancel_balances)
    assert_model(Order, before_cancel_orders)

    assert_difference('OrderCancel.count') do
      post order_cancels_url, params: { order_cancel: { account_address: @order_cancel.account_address, cancel_hash: @order_cancel.cancel_hash, nonce: @order_cancel.nonce, order_hash: @order_cancel.order_hash, signature: @order_cancel.signature } }, as: :json
    end

    assert_response 201

    assert_model(Balance, after_cancel_balances)
    assert_model(Order, after_cancel_orders)
  end

  test "should cancel a partially filled order and refund" do
    @order_cancel.destroy
    @order.fill(@order.give_amount.to_i / 2)

    before_cancel_balances = [
      { :account_address => @order_cancel.account_address, :token_address => @order_cancel.order.give_token_address, :balance => 0, :hold_balance => 100000000000000000000 }
    ]
    after_cancel_balances = [
      { :account_address => @order_cancel.account_address, :token_address => @order_cancel.order.give_token_address, :balance => 50000000000000000000, :hold_balance => 50000000000000000000 }
    ]
    before_cancel_orders = [
      { :order_hash => @order.order_hash, :status => "open" }
    ]
    after_cancel_orders = [
      { :order_hash => @order.order_hash, :status => "cancelled" } 
    ]

    assert_model(Balance, before_cancel_balances)
    assert_model(Order, before_cancel_orders)

    assert_difference('OrderCancel.count') do
      post order_cancels_url, params: { order_cancel: { account_address: @order_cancel.account_address, cancel_hash: @order_cancel.cancel_hash, nonce: @order_cancel.nonce, order_hash: @order_cancel.order_hash, signature: @order_cancel.signature } }, as: :json
    end

    assert_response 201

    assert_model(Balance, after_cancel_balances)
    assert_model(Order, after_cancel_orders)
  end

  # test "should show order_cancel" do
  #   get order_cancel_url(@order_cancel), as: :json
  #   assert_response :success
  # end

  # test "should update order_cancel" do
  #   patch order_cancel_url(@order_cancel), params: { order_cancel: { account_address: @order_cancel.account_address, cancel_hash: @order_cancel.cancel_hash, nonce: @order_cancel.nonce, order_hash: @order_cancel.order_hash, signature: @order_cancel.signature } }, as: :json
  #   assert_response 200
  # end

  # test "should destroy order_cancel" do
  #   assert_difference('OrderCancel.count', -1) do
  #     delete order_cancel_url(@order_cancel), as: :json
  #   end

  #   assert_response 204
  # end
end
