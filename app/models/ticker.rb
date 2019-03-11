class Ticker < ApplicationRecord
  def self.find_by_market_symbol(symbol)
    market = Market.find_by({ :symbol => symbol })

    if (!market)
      return
    end

    # p market.percent_change_24h

    return {
      :base_token_address => market.base_token_address,
      :quote_token_address => market.quote_token_address,
      :symbol => market.symbol,
    }
  end
end
