require 'test_helper'

class OrderTest < ActiveSupport::TestCase
	setup do
		@order = orders(:one)
		@old_contract_address = ENV['CONTRACT_ADDRESS'].without_checksum
		ENV['CONTRACT_ADDRESS'] = "0x4ef6474f40bf5c9dbc013efaac07c4d0cb17219a"
	end

	teardown do
		ENV['CONTRACT_ADDRESS'] = @old_contract_address
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
  	new_order = Order.new(:account_address => @order.account_address, :give_token_address => @order.give_token_address, :give_amount => @order.give_amount, :take_token_address => @order.take_token_address, :take_amount => @order.take_amount, :nonce => 0, :expiry_timestamp_in_milliseconds => @order.expiry_timestamp_in_milliseconds, :order_hash => @order.order_hash, :signature => @order.signature)
  	assert_not new_order.valid?
  	assert_equal new_order.errors.messages[:nonce], ['must be greater than last nonce']
  end

  test "market must exist" do
  	@order.take_token_address = 'INVALID'
  	assert_not @order.valid?
  	assert_equal @order.errors.messages[:market], ['market does not exist']
  end

  test "order_hash must be valid" do
  	assert @order.valid?
  	valid_order_hash = @order.order_hash
  	@order.order_hash = 'invalid_order_hash'
  	assert_not @order.valid?
  	@order.order_hash = valid_order_hash
  	assert @order.valid?
  end

  test "signature must be from account_address" do
  	assert @order.valid?
  	valid_signature = @order.signature
  	@order.signature = 'invalid_signature'
  	assert_not @order.valid?
  	@order.signature = valid_signature
  	assert @order.valid?
  end

  test "balance must be sufficient" do
    new_order = Order.new(:account_address => @order.account_address, :give_token_address => @order.give_token_address, :give_amount => @order.give_amount.to_i + 1, :take_token_address => @order.take_token_address, :take_amount => @order.take_amount, :nonce => @order.nonce, :expiry_timestamp_in_milliseconds => @order.expiry_timestamp_in_milliseconds, :order_hash => @order.order_hash, :signature => @order.signature)
  	assert_not new_order.valid?
  	assert_equal new_order.errors.messages[:account_address], ["insufficient balance"]
  end

  test "filled cannot be negative" do
    @order.filled = -1
    assert_not @order.valid?
    assert_equal @order.errors.messages[:filled], ["must be greater than or equal to 0"]
  end

  test "filled must not exceed give_amount" do
    @order.filled = @order.give_amount.to_i + 1
    assert_not @order.valid?
    assert_equal @order.errors.messages[:filled], ["must not exceed give_amount"]
  end

  test "status can only be open, closed or partially_filled" do
    @order.status = 'INVALID'
    assert_not @order.valid?
    assert_equal @order.errors.messages[:status], ["must be open, closed or partially_filled"]
  end

  test "cannot be created if market is disabled" do
    # we have invalid existing orders that cannot be cancelled
    @order.market.open_orders.destroy_all
    @order.market.disable
    new_order = Order.new(:account_address => @order.account_address, :give_token_address => @order.give_token_address, :give_amount => @order.give_amount, :take_token_address => @order.take_token_address, :take_amount => @order.take_amount, :nonce => 0, :expiry_timestamp_in_milliseconds => @order.expiry_timestamp_in_milliseconds, :order_hash => @order.order_hash, :signature => @order.signature)
    assert_not new_order.valid?
    assert_equal new_order.errors.messages[:market], ['has been disabled']
  end

  test "automatically cancelled and refunded when market is disabled" do
    # we have invalid existing orders that cannot be cancelled
    @order.market.open_orders.destroy_all
    deposit_data = [
      { :account_address => @order.account_address, :token_address => @order.give_token_address, :amount => @order.give_amount }
    ]
    batch_deposit(deposit_data)
    original_balance = @order.account.balance(@order.give_token_address).balance

    new_order = Order.create(generate_order(@order))
    before_cancel_balance = @order.account.balance(@order.give_token_address).balance
    assert_not_equal original_balance, before_cancel_balance

    new_order.market.disable
    new_order.reload
    after_cancel_balance = @order.account.balance(@order.give_token_address).balance
    assert_equal original_balance, after_cancel_balance
    assert_equal new_order.status, 'closed'
  end

  test "sell orders volume must be greater than minimum on create" do
    new_sell_order = Order.new(:account_address => @order.account_address, :give_token_address => @order.give_token_address, :give_amount => @order.give_amount, :take_token_address => @order.take_token_address, :take_amount => ENV['MAKER_MINIMUM_ETH_IN_WEI'].to_i - 1, :nonce => 0, :expiry_timestamp_in_milliseconds => @order.expiry_timestamp_in_milliseconds, :order_hash => @order.order_hash, :signature => @order.signature)
    assert_not new_sell_order.valid?
    assert_equal new_sell_order.errors.messages[:take_amount], ["must be greater than #{ENV['MAKER_MINIMUM_ETH_IN_WEI']}"]
  end

  test "buy orders volume must be greater than minimum on create" do
    new_buy_order = Order.new(:account_address => @order.account_address, :give_token_address => @order.take_token_address, :give_amount => ENV['MAKER_MINIMUM_ETH_IN_WEI'].to_i - 1, :take_token_address => @order.give_token_address, :take_amount => ENV['MAKER_MINIMUM_ETH_IN_WEI'].to_i - 1, :nonce => 0, :expiry_timestamp_in_milliseconds => @order.expiry_timestamp_in_milliseconds, :order_hash => @order.order_hash, :signature => @order.signature)
    assert_not new_buy_order.valid?
    assert_equal new_buy_order.errors.messages[:give_amount], ["must be greater than #{ENV['MAKER_MINIMUM_ETH_IN_WEI']}"]
  end

 # test "calculate_take_amount should handle overly-specific amounts" do
 #  order = Order.new(:give_amount => 195738239776775570, :take_amount => 59744193591648150)
 #  give_amount = order.calculate_take_amount(50000000000000000)
 #  assert_equal take_amount, 15261247281006975
 # end
end
