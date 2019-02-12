require 'test_helper'

class MarketTest < ActiveSupport::TestCase
	setup do
		@market = markets(:one)
	end

  test "market must be unique" do
  	newMarket = Market.new(:base_token_address => @market.base_token_address, :quote_token_address => @market.quote_token_address)
    assert_not newMarket.valid?
  end

  test "quote token address must not equal to base" do
  	@market.quote_token_address = @market.base_token_address
  	assert_not @market.valid?
  end
end
