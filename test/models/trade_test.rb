require 'test_helper'

class TradeTest < ActiveSupport::TestCase
  setup do
		@trade = trades(:one)
		@old_contract_address = ENV['CONTRACT_ADDRESS'].without_checksum
		ENV['CONTRACT_ADDRESS'] = "0x4ef6474f40bf5c9dbc013efaac07c4d0cb17219a"
	end

	teardown do
		ENV['CONTRACT_ADDRESS'] = @old_contract_address
	end

	test "account_address must have sufficient balance" do
    new_trade = Trade.new({ :account_address => @trade.account_address, :order_hash => @trade.order_hash, :amount => @trade.amount.to_i * 1000 })
		assert_not new_trade.valid?
		assert_equal new_trade.errors.messages[:account_address], ["insufficient balance"]
	end

	test "nonce must be greater than last nonce" do
		new_trade = Trade.new(:account_address => @trade.account_address, :order_hash => @trade.order_hash, :amount => @trade.amount, :nonce => 1, :trade_hash => @trade.trade_hash, :signature => @trade.signature)
		assert_not new_trade.valid?
		assert_equal new_trade.errors.messages[:nonce], ["must be greater than last nonce"]
	end

	test "order_hash must be valid" do
		@trade.order_hash = "INVALID"
		assert_not @trade.valid?
		assert_equal @trade.errors.messages[:order], ["must exist"]
	end

	test "trade_hash must be valid" do
		@trade.trade_hash = "INVALID"
		assert_not @trade.valid?
		assert_equal @trade.errors.messages[:trade_hash], ["invalid"]
	end

  test "signature must be valid" do
    @trade.signature = "INVALID"
    assert_not @trade.valid?
    assert_equal @trade.errors.messages[:signature], ["invalid"]
  end

  test "trade volume must be greater than minimum" do
    @trade.amount = 1
    assert_not @trade.valid?
    assert_equal @trade.errors.messages[:amount], [ "must be greater than #{ENV['TAKER_MINIMUM_ETH_IN_WEI']}"]
  end

  test "trade's order must be open" do
    new_trade = Trade.new(generate_trade({:account_address => @trade.account_address, :order_hash => @trade.order_hash, :amount => @trade.amount}))
    assert_not new_trade.valid?
    assert_equal new_trade.errors.messages[:order], ['must be open', 'must have sufficient volume']
  end

  test "trade's order must have enough volume" do
    new_trade = Trade.new(generate_trade({ :account_address => @trade.account_address, :order_hash => @trade.order_hash, :amount => @trade.amount }))
    assert_not new_trade.valid?
    assert_equal new_trade.errors.messages[:order], ['must be open', 'must have sufficient volume']
  end

  test "cannot be created if market has been disabled" do
    # we have invalid existing orders that cannot be cancelled
    @trade.market.open_orders.destroy_all
    @trade.market.disable
    new_trade = Trade.new({ :account_address => @trade.account_address, :order_hash => @trade.order_hash, :amount => @trade.amount })
    assert_not new_trade.valid?
    assert_equal new_trade.errors.messages[:market], ['has been disabled']
  end
end
