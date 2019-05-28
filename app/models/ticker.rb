class Ticker < ApplicationRecord
  validates :market_symbol, uniqueness: true

  def self.find_by_market_symbol(symbol)
    market = Market.find_by({ :symbol => symbol })

    if (!market)
      return
    end

    return build_ticker(market)
  end

  def self.find_all_and_paginate(page, per_page)
    markets = Market.paginate(:page => page, :per_page => per_page)

    paginated_tickers = {
      :total_entries => markets.total_entries,
      :current_page => Integer(markets.current_page),
      :per_page => markets.per_page,
      :records => []
    }

    markets.each do |market|
      paginated_tickers[:records].push(build_ticker(market))
    end

    return paginated_tickers
  end

  def self.build_ticker(market)
    ticker = {
      :base_token_address => market.base_token_address,
      :quote_token_address => market.quote_token_address,
      :symbol => market.symbol,
      :last => market.last_price ? market.last_price.to_s : nil,
      :high => market.high ? market.high.to_s : nil,
      :low => market.low ? market.low.to_s : nil,
      :lowest_ask => market.lowest_ask ? market.lowest_ask.to_s : nil,
      :highest_bid => market.highest_bid ? market.highest_bid.to_s : nil,
      :percent_change => market.percent_change_24h.to_s,
      :base_volume => market.volume.to_s,
      :quote_volume => market.quote_volume.to_s
    }
    return ticker
  end
end
