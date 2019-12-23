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

  test "cannot be created if market has been disabled" do
    # we have invalid existing orders that cannot be cancelled
    @trade.market.open_orders.destroy_all
    @trade.market.disable
    new_trade = Trade.new({ :account_address => @trade.account_address, :order_hash => @trade.order_hash, :amount => @trade.amount })
    assert_not new_trade.valid?
    assert_equal new_trade.errors.messages[:market], ['has been disabled']
  end
end
