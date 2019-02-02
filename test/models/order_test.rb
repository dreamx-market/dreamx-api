require 'test_helper'

class OrderTest < ActiveSupport::TestCase
	setup do
		@order = orders(:one)
	end

	test "amounts cannot be 0" do
  	@order.give_amount = 0
  	@order.take_amount = 0
  	assert_not @order.valid?
  end

  test "expiry timestamp must be in the future" do
  	@order.expiry_timestamp_in_milliseconds = 10.days.ago
  	assert_not @order.valid?
  end

  test "nonce cannot be lesser than last nonce" do
  	newOrder = Order.new(:account_address => @order.account_address, :give_token_address => @order.give_token_address, :give_amount => @order.give_amount, :take_token_address => @order.take_token_address, :take_amount => @order.take_amount, :nonce => 0, :expiry_timestamp_in_milliseconds => @order.expiry_timestamp_in_milliseconds, :order_hash => @order.order_hash, :signature => @order.signature)
  	assert_not newOrder.valid?
  	assert_equal newOrder.errors.messages[:nonce], ['must be greater than last nonce']
  end

  test "market must exist" do
  	@order.take_token_address = 'INVALID'
  	assert_not @order.valid?
  	assert_equal @order.errors.messages[:give_token], ['market does not exist']
  	assert_equal @order.errors.messages[:take_token], ['market does not exist']
  end
end
