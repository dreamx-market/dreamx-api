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

	# test "" do
	# end
end
