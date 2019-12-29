class OrderBook < ApplicationRecord
  def self.find_by_market_symbol(symbol, page=nil, per_page=nil)
    market = Market.find_by({ :symbol => symbol })

    if (!market)
      return nil
    end

    buybook = market.open_buy_orders
                    .sort_by { |order| [-order.price, order.created_at.to_i] }
                    .paginate(:page => page, :per_page => per_page)
    sellbook = market.open_sell_orders
                      .sort_by { |order| [order.price, order.created_at.to_i] }
                      .paginate(:page => page, :per_page => per_page)

    return {
      :buybook => buybook,
      :sellbook => sellbook
    }
  end
end
