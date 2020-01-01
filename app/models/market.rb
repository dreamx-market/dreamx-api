class Market < ApplicationRecord
  include NonDestroyable
  include NonUpdatable
  non_updatable_attrs :symbol, :base_token_address, :quote_token_address

  has_many :chart_data, class_name: 'ChartDatum', foreign_key: 'market_symbol', primary_key: 'symbol' do
    def by_period(period)
      where({ period: period })
    end
  end
  has_many :open_orders, -> { open }, class_name: 'Order', foreign_key: 'market_symbol', primary_key: 'symbol'
  has_many :open_buy_orders, -> { open_buy }, class_name: 'Order', foreign_key: 'market_symbol', primary_key: 'symbol'
  has_many :open_sell_orders, -> { open_sell }, class_name: 'Order', foreign_key: 'market_symbol', primary_key: 'symbol'
  has_many :trades, foreign_key: 'market_symbol', primary_key: 'symbol' do
    def within_period(period=nil)
      @to ||= Time.current
      from = period ? @to - period : Time.at(0)
      AppLogger.log("queried for trades from: #{from.to_i} to: #{@to.to_i}")
      where({ :created_at => from..@to })
    end
  end
  has_one :ticker, foreign_key: 'market_symbol', primary_key: 'symbol'
	belongs_to :base_token, class_name: 'Token', foreign_key: 'base_token_address', primary_key: 'address'
	belongs_to :quote_token, class_name: 'Token', foreign_key: 'quote_token_address', primary_key: 'address'

  validates :status, inclusion: { in: ['active', 'disabled'] }
  validate :immutable_attributes_cannot_be_updated, on: :update
	validates_uniqueness_of :base_token_address, scope: [:quote_token_address]
	validate :base_and_quote_must_not_equal, :cannot_be_the_reverse_of_an_existing_market

  before_validation :initialize_attributes, on: :create
  before_create :remove_checksum, :assign_symbol

  class << self
  end

  def order_book(page=nil, per_page=nil)
    buy_book = self.open_buy_orders
                    .order(price: :desc, created_at: :asc)
                    .paginate(:page => page, :per_page => per_page)
    sell_book = self.open_sell_orders
                      .order(price: :asc, created_at: :asc)
                      .paginate(:page => page, :per_page => per_page)
    return { buy_book: buy_book, sell_book: sell_book }
  end

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

  def average_price(period)
    if (!self.high(period) or !self.low(period))
      return nil
    end

    return ((self.high(period).to_d + self.low(period).to_d) / 2).to_s
  end

	def base_and_quote_must_not_equal
		errors.add(:quote_token_address, 'Quote token address must not equal to base') if base_token_address == quote_token_address
	end

	def cannot_be_the_reverse_of_an_existing_market
		existing_market = Market.find_by(:base_token_address => quote_token_address, :quote_token_address => base_token_address)
		errors.add(:quote_token_address, 'Market already exists') if existing_market
	end

  def last_price(period=1.day)
    trades_sorted_by_nonce_asc = self.trades.within_period(period).order(:nonce)
    return trades_sorted_by_nonce_asc.empty? ? nil : trades_sorted_by_nonce_asc.last.price.to_s
  end

  def high(period=1.day)
    trades_within_period_sorted_by_price_asc = self.trades.within_period(period).order(:price)
    return trades_within_period_sorted_by_price_asc.empty? ? nil : trades_within_period_sorted_by_price_asc.last.price.to_s
  end

  def low(period=1.day)
    trades_within_period_sorted_by_price_asc = self.trades.within_period(period).order(:price)
    return trades_within_period_sorted_by_price_asc.empty? ? nil : trades_within_period_sorted_by_price_asc.first.price.to_s
  end

  def lowest_ask   
    sell_orders_sorted_by_price_asc = self.open_sell_orders.order(:price)
    return sell_orders_sorted_by_price_asc.empty? ? nil : sell_orders_sorted_by_price_asc.first.price
  end

  def highest_bid
    buy_orders_sorted_by_price_asc = self.open_buy_orders.order(:price)
    return buy_orders_sorted_by_price_asc.empty? ? nil : buy_orders_sorted_by_price_asc.last.price
  end

  def volume(period=1.day)
    result = 0
    self.trades.within_period(period).each do |trade|
      if trade.sell
        result += trade.amount.to_i
      else
        result += trade.take_amount.to_i
      end
    end
    return result.to_s.from_wei
  end

  def quote_volume(period=1.day)
    result = 0
    self.trades.within_period(period).each do |trade|
      if trade.sell
        result += trade.take_amount.to_i
      else
        result += trade.amount.to_i
      end
    end
    return result.to_s.from_wei
  end

  def percent_change_24h
    previous_24h = self.price_previous_24h
    last = self.last_price

    if !previous_24h or !last
      return 0.to_d
    end

    return ((last.to_d * 100) / previous_24h.to_d) - 100
  end

  def price_previous_24h
    hourly_candle_from_previous_24h = self.chart_data.by_period(1.hour).order(:created_at).last(24).first
    return hourly_candle_from_previous_24h ? hourly_candle_from_previous_24h.close : nil
  end

  def initialize_attributes
    self.ticker ||= Ticker.new
  end

  private

  def remove_checksum
    self.base_token_address = self.base_token_address.without_checksum
    self.quote_token_address = self.quote_token_address.without_checksum
  end

  def assign_symbol
    self.symbol = "#{self.base_token.symbol}_#{self.quote_token.symbol}"
  end
end
