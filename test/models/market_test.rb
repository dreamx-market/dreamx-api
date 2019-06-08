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

  test "delete method is disabled" do
    assert_no_changes('Market.count') do
      begin
        @market.delete
      rescue
      end
    end
  end

  test "destroy method is disabled" do
    assert_no_changes('Market.count') do
      begin
        @market.destroy
      rescue
      end
    end
  end

  test "delete_all method is disabled" do
    assert_no_changes('Market.count') do
      begin
        Market.delete_all
      rescue
      end
    end
  end

  test "destroy_all method is disabled" do
    assert_no_changes('Market.count') do
      begin
        Market.delete_all
      rescue
      end
    end
  end

  test "cannot be updated" do
    assert_no_changes('@market.symbol') do
      @market.update({ :symbol => "ABC_123" })
      @market.reload
    end

    assert_no_changes('@market.base_token_address') do
      @market.update({ :base_token_address => "NEW_ADDRESS" })
      @market.reload
    end

    assert_no_changes('@market.quote_token_address') do
      @market.update({ :quote_token_address => "NEW_ADDRESS" })
      @market.reload
    end
  end

  test "newly created markets are disabled by default" do
    market = Market.create({ :base_token_address => "0x0000000000000000000000000000000000000000", :quote_token_address => "0x8137064a86006670d407c24e191b5a55da5b2889" })
    assert_equal market.status, 'disabled'
  end

  test "market status can only be 'active' or 'disabled'" do
    market = Market.new({ :base_token_address => "0x0000000000000000000000000000000000000000", :quote_token_address => "0x8137064a86006670d407c24e191b5a55da5b2889" })

    market.status = 'disabled'
    assert market.valid?

    market.status = 'active'
    assert market.valid?

    market.status = 'ABC123'
    assert_not market.valid?
  end

  test "enable and disable market" do
    market = Market.create({ :base_token_address => "0x0000000000000000000000000000000000000000", :quote_token_address => "0x8137064a86006670d407c24e191b5a55da5b2889" })
    assert_equal market.status, 'disabled'

    market.enable
    assert_equal market.status, 'active'

    market.disable
    assert_equal market.status, 'disabled'
  end
end
