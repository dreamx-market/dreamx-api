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
end
