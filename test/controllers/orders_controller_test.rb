require 'test_helper'

class OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @order = orders(:one)
    @old_contract_address = ENV['CONTRACT_ADDRESS']
		ENV['CONTRACT_ADDRESS'] = "0x4ef6474f40bf5c9dbc013efaac07c4d0cb17219a"
  end

  teardown do
		ENV['CONTRACT_ADDRESS'] = @old_contract_address
	end

  # test "should get index" do
  #   get orders_url, as: :json
  #   assert_response :success
  # end

  # test "should create order and reduce account's balance" do
  #   uncreate_order(@order)

  # 	balance = Balance.find_by(:account_address => @order.account_address, :token_address => @order.give_token_address)
  # 	old_balance = balance.balance
  # 	old_hold_balance = balance.hold_balance

  # 	assert_difference("Order.count") do
  #     post orders_url, params: { order: { account_address: @order.account_address, expiry_timestamp_in_milliseconds: @order.expiry_timestamp_in_milliseconds, give_amount: @order.give_amount, give_token_address: @order.give_token_address, nonce: @order.nonce, order_hash: @order.order_hash, signature: @order.signature, take_amount: @order.take_amount, take_token_address: @order.take_token_address } }, as: :json
  #   end

  #   assert_response 201

  #   balance.reload
  #   new_balance = balance.balance
  #   new_hold_balance = balance.hold_balance

  #   assert_equal new_balance.to_i, old_balance.to_i - @order.give_amount.to_i
  #   assert_equal new_hold_balance.to_i, old_hold_balance.to_i + @order.give_amount.to_i
  # end

  # test "should not reduce balance if order failed to save" do
  # 	balance = Balance.find_by(:account_address => @order.account_address, :token_address => @order.give_token_address)
  # 	old_balance = balance.balance
  # 	old_hold_balance = balance.hold_balance

  # 	post orders_url, params: { order: { account_address: @order.account_address, expiry_timestamp_in_milliseconds: @order.expiry_timestamp_in_milliseconds, give_amount: @order.give_amount, give_token_address: @order.give_token_address, nonce: @order.nonce, order_hash: @order.order_hash, signature: @order.signature, take_amount: @order.take_amount, take_token_address: @order.take_token_address } }, as: :json
  #   assert_response 422

  #   balance.reload
  #   new_balance = balance.balance
  #   new_hold_balance = balance.hold_balance

  #   assert_equal new_balance.to_i, old_balance.to_i
  #   assert_equal new_hold_balance.to_i, old_hold_balance.to_i
  # end

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
