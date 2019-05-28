require 'test_helper'

class MarketTest < ActiveSupport::TestCase
	setup do
		@market = markets(:one)
	end

  test "market must be unique" do
  	new_market = Market.new(:base_token_address => @market.base_token_address, :quote_token_address => @market.quote_token_address)
    assert_not new_market.valid?
    new_market_reversed = Market.new(:base_token_address => @market.quote_token_address, :quote_token_address => @market.base_token_address)
    assert_not new_market_reversed.valid?
  end

  test "quote token address must not equal to base" do
  	@market.quote_token_address = @market.base_token_address
  	assert_not @market.valid?
  end

  test "cannot be destroyed" do
    assert_no_changes('Market.count') do
      begin
        @market.delete
      rescue
      end
    end
  end
end
