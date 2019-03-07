class OrderBook < ApplicationRecord
  def self.find_by_symbol(symbol, page=nil, per_page=nil)
    base, quote = symbol.split("_")

    base_token = Token.find_by({ :symbol => base })
    quote_token = Token.find_by({ :symbol => quote })

    if (!base_token or !quote_token)
      return
    end

    buybook = Order.paginate(:page => page, :per_page => per_page).where({ :give_token_address => base_token.address, :take_token_address => quote_token.address }).where.not({ status: 'closed' })
    sellbook = Order.paginate(:page => page, :per_page => per_page).where({ :give_token_address => quote_token.address, :take_token_address => base_token.address }).where.not({ status: 'closed' })

    return {
      :buybook => buybook,
      :sellbook => sellbook
    }
  end
end
