class Market < ApplicationRecord
  include NonDestroyable
  include NonUpdatable
  non_updatable_attrs :symbol, :base_token_address, :quote_token_address
  validate :immutable_attributes_cannot_be_updated, on: :update

  has_many :chart_data, class_name: 'ChartDatum', foreign_key: 'market_symbol', primary_key: 'symbol'
  has_one :ticker, class_name: 'Ticker', foreign_key: 'market_symbol', primary_key: 'symbol'
	belongs_to :base_token, class_name: 'Token', foreign_key: 'base_token_address', primary_key: 'address'
	belongs_to :quote_token, class_name: 'Token', foreign_key: 'quote_token_address', primary_key: 'address'
	validates_uniqueness_of :base_token_address, scope: [:quote_token_address]
	validate :status_must_be_active_or_disabled, :base_and_quote_must_not_equal, :cannot_be_the_reverse_of_an_existing_market

  before_create :remove_checksum, :assign_symbol, :create_ticker

  def disabled?
    return self.status == 'disabled' ? true : false
  end

  def enable
    self.update!({ :status => 'active' })
  end

  def disable
    ActiveRecord::Base.transaction do
      self.open_orders.each do |order|
        order.cancel
      end
      self.update!({ :status => 'disabled' })
    end
  end

  def status_must_be_active_or_disabled
    valid_states = ['active', 'disabled']

    if (!valid_states.include?(self.status))
      errors.add(:status, 'Must be active or disabled')
    end
  end

  def average_price(period)
    if (!self.high(period) or !self.low(period))
      return nil
    end

    return ((self.high(period).to_f + self.low(period).to_f) / 2).to_s
  end

	def base_and_quote_must_not_equal
		errors.add(:quote_token_address, 'Quote token address must not equal to base') if base_token_address == quote_token_address
	end

	def cannot_be_the_reverse_of_an_existing_market
		existing_market = Market.find_by(:base_token_address => quote_token_address, :quote_token_address => base_token_address)
		errors.add(:quote_token_address, 'Market already exists') if existing_market
	end

  def open_orders
    return self.open_buy_orders.or(self.open_sell_orders)
  end

  def open_buy_orders
    return Order.where({ :give_token_address => self.base_token_address, :take_token_address => self.quote_token_address }).where.not({ status: 'closed' })
  end

  def open_sell_orders
    return Order.where({ :give_token_address => self.quote_token_address, :take_token_address => self.base_token_address }).where.not({ status: 'closed' })
  end

  def all_trades
    return Trade.joins(:order).where(:orders => { :give_token_address => self.base_token_address, :take_token_address => self.quote_token_address }).or(Trade.joins(:order).where(:orders => { :give_token_address => self.quote_token_address, :take_token_address => self.base_token_address }))
  end

  def all_trades
    Trade.joins(:order).where(:orders => { :give_token_address => self.base_token_address, :take_token_address => self.quote_token_address }).or(Trade.joins(:order).where(:orders => { :give_token_address => self.quote_token_address, :take_token_address => self.base_token_address })) 
  end

  def trades(period=nil)
    @memoized_current_time ||= Time.current
    trades = []

    if (!period)
      # return all trades
      trades = self.all_trades
    else
      # return trades within the period
      trades = self.all_trades.where({ :created_at => (@memoized_current_time - period)..@memoized_current_time }).includes(:order)
    end

    trades.includes(:order)
  end

  def last_price(period=1.day)
    @trades_within_period ||= self.trades(period)
    trades_sorted_by_nonce_asc = @trades_within_period.sort_by { |trade| trade.nonce.to_i }
    return trades_sorted_by_nonce_asc.empty? ? nil : trades_sorted_by_nonce_asc.last.price.to_s
  end

  def high(period=1.day)
    @trades_within_period ||= self.trades(period)
    trades_within_period_sorted_by_price_asc = @trades_within_period.sort_by { |trade| trade.price }
    return trades_within_period_sorted_by_price_asc.empty? ? nil : trades_within_period_sorted_by_price_asc.last.price.to_s
  end

  def low(period=1.day)
    @trades_within_period ||= self.trades(period)
    trades_within_period_sorted_by_price_asc = @trades_within_period.sort_by { |trade| trade.price }
    return trades_within_period_sorted_by_price_asc.empty? ? nil : trades_within_period_sorted_by_price_asc.first.price.to_s
  end

  def lowest_ask
    sell_orders_sorted_by_price_asc = self.open_sell_orders.sort_by { |order| order.price }
    return sell_orders_sorted_by_price_asc.empty? ? nil : sell_orders_sorted_by_price_asc.first.price
  end

  def highest_bid
    buy_orders_sorted_by_price_asc = self.open_buy_orders.sort_by { |order| order.price }
    return buy_orders_sorted_by_price_asc.empty? ? nil : buy_orders_sorted_by_price_asc.last.price
  end

  def volume(period=1.day)
    @trades_within_period ||= self.trades(period)

    result = 0
    @trades_within_period.each do |trade|
      if trade.is_sell
        result += trade.amount.to_i
      else
        result += trade.order.calculate_take_amount(trade.amount)
      end
    end
    return result.to_s.to_ether
  end

  def quote_volume(period=1.day)
    @trades_within_period ||= self.trades(period)

    result = 0
    @trades_within_period.each do |trade|
      if trade.is_sell
        result += trade.order.calculate_take_amount(trade.amount)
      else
        result += trade.amount.to_i
      end
    end
    return result.to_s.to_ether
  end

  def percent_change_24h
    previous_24h = self.price_previous_24h
    last = self.last_price

    if !previous_24h or !last
      return 0.to_f
    end

    return ((last.to_f * 100) / previous_24h.to_f) - 100
  end

  def price_previous_24h
    if (self.chart_data_by(1.hour).count < 24)
      return nil
    end

    return self.chart_data_by(1.hour).last(24).sort_by { |chart_datum| chart_datum.created_at }.first.close
  end

  def chart_data_by(period)
    return self.chart_data.where({ :period => period.to_s })
  end

  private

  def remove_checksum
    self.base_token_address = self.base_token_address.without_checksum
    self.quote_token_address = self.quote_token_address.without_checksum
  end

  def assign_symbol
    self.symbol = "#{self.base_token.symbol}_#{self.quote_token.symbol}"
  end

  def create_ticker
    Ticker.create!({ :market_symbol => self.symbol })
  end
end
