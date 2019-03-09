class Market < ApplicationRecord
	belongs_to :base_token, class_name: 'Token', foreign_key: 'base_token_address', primary_key: 'address'
	belongs_to :quote_token, class_name: 'Token', foreign_key: 'quote_token_address', primary_key: 'address'
	validates_uniqueness_of :base_token_address, scope: [:quote_token_address]
	validate :base_and_quote_must_not_equal, :cannot_be_the_reverse_of_an_existing_market, :symbol_must_be_valid

  validates :symbol, presence: true

	def base_and_quote_must_not_equal
		errors.add(:quote_token_address, 'Quote token address must not equal to base') if base_token_address == quote_token_address
	end

	def cannot_be_the_reverse_of_an_existing_market
		existing_market = Market.find_by(:base_token_address => quote_token_address, :quote_token_address => base_token_address)
		errors.add(:quote_token_address, 'Market already exists') if existing_market
	end

  def symbol_must_be_valid
    if !self.symbol
      return
    end

    base, quote = self.symbol.split("_")
    base_token = Token.find_by({ :symbol => base })
    quote_token = Token.find_by({ :symbol => quote })

    if (
      !base_token or base_token.address != self.base_token_address or
      !quote_token or quote_token.address != self.quote_token_address
    )
      errors.add(:symbol, 'invalid')
    end
  end

  def open_buy_orders
    return Order.where({ :give_token_address => self.base_token_address, :take_token_address => self.quote_token_address }).where.not({ status: 'closed' })
  end

  def open_sell_orders
    return Order.where({ :give_token_address => self.quote_token_address, :take_token_address => self.base_token_address }).where.not({ status: 'closed' })
  end

  def trades
    return Trade.joins(:order).where(:orders => { :give_token_address => self.base_token_address, :take_token_address => self.quote_token_address }).or(Trade.joins(:order).where(:orders => { :give_token_address => self.quote_token_address, :take_token_address => self.base_token_address }))
  end

  def trades_24h
    return trades.where({ :created_at => 1.day.ago..Time.current })
  end

  def last_price
    @trades ||= self.trades
    trades_sorted_by_nonce_asc = @trades.sort_by { |trade| trade.nonce.to_i }
    return trades_sorted_by_nonce_asc.empty? ? nil : trades_sorted_by_nonce_asc.last.price
  end

  def high_24h
    @trades_24h ||= self.trades_24h
    trades_24h_sorted_by_price_asc = @trades_24h.sort_by { |trade| trade.price }
    return trades_24h_sorted_by_price_asc.empty? ? nil : trades_24h_sorted_by_price_asc.last.price
  end

  def low_24h
    @trades_24h ||= self.trades_24h
    trades_24h_sorted_by_price_asc = @trades_24h.sort_by { |trade| trade.price }
    return trades_24h_sorted_by_price_asc.empty? ? nil : trades_24h_sorted_by_price_asc.first.price
  end

  def lowest_ask
    @sell_orders_sorted_by_price_asc = self.open_sell_orders.sort_by { |order| order.price }
    return @sell_orders_sorted_by_price_asc.empty? ? nil : @sell_orders_sorted_by_price_asc.first.price
  end

  def highest_bid
    @buy_orders_sorted_by_price_asc ||= self.open_buy_orders.sort_by { |order| order.price }
    return @buy_orders_sorted_by_price_asc.empty? ? nil : @buy_orders_sorted_by_price_asc.last.price
  end

  def base_volume_24h
    @trades_24h ||= self.trades_24h

    result = 0
    @trades_24h.each do |trade|
      if trade.is_sell
        result += trade.amount.to_i
      else
        result += trade.order.calculate_take_amount(trade.amount)
      end
    end
    return result
  end

  def quote_volume_24h
    @trades_24h ||= self.trades_24h

    result = 0
    @trades_24h.each do |trade|
      if trade.is_sell
        result += trade.order.calculate_take_amount(trade.amount)
      else
        result += trade.amount.to_i
      end
    end
    return result
  end

  def percent_change_24h
    return 0
  end
end
