require 'test_helper'

class OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @order = orders(:one)
  end

  # test "should get index" do
  #   get orders_url, as: :json
  #   assert_response :success
  # end

  test "should create order" do
  	assert_difference('Order.count') do
      post orders_url, params: { order: { account_address: @order.account_address, expiry_timestamp_in_milliseconds: @order.expiry_timestamp_in_milliseconds, give_amount: @order.take_amount, give_token_address: @order.give_token_address, nonce: Integer(Time.now), order_hash: @order.order_hash, signature: @order.signature, take_amount: @order.take_amount, take_token_address: @order.take_token_address } }, as: :json
    end

    assert_response 201
  end

  # test "should show order" do
  #   get order_url(@order), as: :json
  #   assert_response :success
  # end

  # test "should update order" do
  #   patch order_url(@order), params: { order: { account: @order.account, expiryTimestampInMilliseconds: @order.expiryTimestampInMilliseconds, giveAmount: @order.giveAmount, giveTokenAddress: @order.giveTokenAddress, nonce: @order.nonce, orderHash: @order.orderHash, signature: @order.signature, takeAmount: @order.takeAmount, takeTokenAddress: @order.takeTokenAddress } }, as: :json
  #   assert_response 200
  # end

  # test "should destroy order" do
  #   assert_difference('Order.count', -1) do
  #     delete order_url(@order), as: :json
  #   end

  #   assert_response 204
  # end
end
