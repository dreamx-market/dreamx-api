class OrderBook < ApplicationRecord
  def self.find_by_market_symbol(symbol, page=nil, per_page=nil)
    market = Market.find_by({ :symbol => symbol })

    if (!market)
      return nil
    end

    buybook = market.open_buy_orders
                    .order(price: :desc, created_at: :asc)
                    .paginate(:page => page, :per_page => per_page)
    sellbook = market.open_sell_orders
                      .order(price: :asc, created_at: :asc)
                      .paginate(:page => page, :per_page => per_page)

    return {
      :buybook => buybook,
      :sellbook => sellbook
    }
  end
end
