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

  test "updating MAKER_MINIMUM does not invalidate existing orders" do
    assert_equal @order.valid?, true
    old_minimum_volume = ENV['MAKER_MINIMUM_ETH_IN_WEI']

    ENV['MAKER_MINIMUM_ETH_IN_WEI'] = (@order.volume.to_i * 2).to_s
    assert_equal @order.valid?, true
  end
end
