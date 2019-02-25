require 'test_helper'

class TradeTest < ActiveSupport::TestCase
  setup do
		@trade = trades(:one)
		@old_contract_address = Rails.application.config.CONTRACT_ADDRESS
		Rails.application.config.CONTRACT_ADDRESS = "0x4ef6474f40bf5c9dbc013efaac07c4d0cb17219a"
	end

	teardown do
		Rails.application.config.CONTRACT_ADDRESS = @old_contract_address
	end

	test "must have a uuid" do
		assert_not_nil @trade.uuid
	end

	test "amount cannot be 0" do
		@trade.amount = 0
		assert_not @trade.valid?
		assert_equal @trade.errors.messages[:amount], ["must be greater than 0"]
	end

	test "account_address must have sufficient balance" do
		@trade.amount = @trade.amount.to_i * 1000000
		assert_not @trade.valid?
		assert_equal @trade.errors.messages[:account_address], ["insufficient balance"]
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
end
