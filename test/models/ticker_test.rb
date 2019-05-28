require 'test_helper'

class TickerTest < ActiveSupport::TestCase
  setup do
    @token_one = tokens(:one)
    @token_three = tokens(:four)
  end

  test "automatically created on market creations" do
    market = Market.create({ :base_token_address => @token_one.address, :quote_token_address => @token_three.address })
    pp Ticker.find_by({ :market_symbol => market.symbol })
    # assert_not_nil Ticker.find_by({ :market_symbol => market.symbol })
  end
end
