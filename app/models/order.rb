class Order < ApplicationRecord
  include AccountNonEjectable

  has_many :trades
  has_one :order_cancel
  belongs_to :give_token, class_name: 'Token', foreign_key: 'give_token_id'
  belongs_to :take_token, class_name: 'Token', foreign_key: 'take_token_id'
	belongs_to :account
  belongs_to :give_balance, class_name: 'Balance', foreign_key: 'give_balance_id', primary_key: 'id'
  belongs_to :take_balance, class_name: 'Balance', foreign_key: 'take_balance_id', primary_key: 'id'
  belongs_to :market
  alias_attribute :balance, :give_balance
  
  validates :order_hash, :nonce, uniqueness: true
  validates :account_address, :give_token_address, :give_amount, :take_token_address, :take_amount, :nonce, :expiry_timestamp_in_milliseconds, :order_hash, :signature, presence: true
  validates :status, inclusion: { in: ['open', 'closed', 'partially_filled'] }
	validates :give_amount, :take_amount, numericality: { greater_than: 0 }
  validates :order_hash, signature: true
  validates :filled, numericality: { :greater_than_or_equal_to => 0 }
	validate :addresses_must_be_valid, :expiry_timestamp_must_be_in_the_future, :order_hash_must_be_valid, :filled_must_not_exceed_give_amount, :account_must_not_be_ejected
  validates :filled, numericality: { :equal_to => 0 }, on: :create
  validate :price_precision_is_valid, :amount_precision_is_valid, :status_must_be_open_on_create, :market_must_be_active, :balance_must_be_sufficient, :volume_must_meet_maker_minimum, on: :create

  before_validation :initialize_attributes, :lock_attributes, on: :create
  before_validation :remove_checksum
	before_create :hold_balance
  after_create :enqueue_update_ticker
  after_commit { 
    MarketOrdersRelayJob.perform_later(self)
    AccountOrdersRelayJob.perform_later(self)
  }

  scope :open, -> { where.not({ status: 'closed' }) }
  scope :open_buy, -> { where({ sell: false }).where.not({ status: 'closed' }) }
  scope :open_sell, -> { where({ sell: true }).where.not({ status: 'closed' }) }
  scope :closed, -> { where({ status: 'closed' }) }
  scope :closed_and_partially_filled, -> { where.not({ status: 'open' }) }

  class << self
  end

  def status_must_be_open_on_create
    if self.status != 'open'
      self.errors.add(:status, 'must be open')
    end
  end

  def v
    signature[-2..signature.length].hex
  end

  def r
    Eth::Utils.hex_to_bin('0x' + signature[2..65])
  end

  def s
    Eth::Utils.hex_to_bin('0x' + signature[66..-3])
  end

  def calculate_take_amount(give_amount)
    return give_amount.to_i * self.take_amount.to_i / self.give_amount.to_i
  end

  def fill(amount, fee=0)
    self.filled += amount.to_i
    self.fee += fee.to_i

    if self.remaining_give_amount == 0 or !self.remaining_volume_is_above_taker_minimum?
      self.status = 'closed'
    else
      self.status = 'partially_filled'
    end

    self.save!
  end

  def remaining_give_amount
    self.give_amount.to_i - self.filled.to_i
  end

  def cancel
    self.status = 'closed'
    self.save!
  end

  def remaining_volume
    if (self.sell) then
      return self.take_amount.to_i - self.calculate_take_amount(self.filled.to_i)
    else
      return self.give_amount.to_i - self.filled.to_i
    end
  end

  def volume_must_meet_maker_minimum
    if (self.sell) then
      attribute = :take_amount
    else
      attribute = :give_amount
    end

    minimum_volume = ENV['MAKER_MINIMUM_ETH_IN_WEI'].to_i
    if self.remaining_volume.to_i < minimum_volume
      self.errors.add(attribute, "must be greater than #{minimum_volume}")
    end
  end

  def remaining_volume_is_above_taker_minimum?
    minimum_volume = ENV['TAKER_MINIMUM_ETH_IN_WEI'].to_i
    return self.remaining_volume >= minimum_volume
  end

  def hold_balance
    self.balance.hold(give_amount)
  end

  def initialize_attributes
    self.give_token = Token.find_by(address: self.give_token_address)
    self.take_token = Token.find_by(address: self.take_token_address)
    self.account = Account.find_by(address: self.account_address)

    if self.account && 
      self.give_token && 
      self.take_token then
      
      self.give_balance = self.account.balance(self.give_token.address)
      self.take_balance = self.account.balance(self.take_token.address)
      self.market = Market.find_by({ :base_token_address => self.take_token.address, :quote_token_address => self.give_token.address }) || Market.find_by({ :base_token_address => self.give_token.address, :quote_token_address => self.take_token.address })
    end

    if self.market
      self.market_symbol = self.market.symbol
      self.sell = self.give_token_address == self.market.base_token_address ? false : true
    end

    if self.sell
      self.price = self.take_amount.to_d / self.give_amount.to_d
    else
      self.price = self.give_amount.to_d / self.take_amount.to_d
    end
  end

	private

  def lock_attributes
    if self.balance
      self.balance.lock!
    end
  end

  def addresses_must_be_valid
    [:account_address, :give_token_address, :take_token_address].each do |key|
      if !self[key].is_a_valid_address?
        self.errors.add(key, 'is invalid')
      end
    end
  end

  def filled_must_not_exceed_give_amount
    self.errors.add(:filled, 'must not exceed give_amount') unless self.filled.to_i <= self.give_amount.to_i
  end

	def expiry_timestamp_must_be_in_the_future
		if self.expiry_timestamp_in_milliseconds.to_i <= Time.now.to_i
			self.errors.add(:expiry_timestamp_in_milliseconds, 'must be in the future')
		end
	end

	def balance_must_be_sufficient
		if !self.balance || self.balance.balance.to_i < self.give_amount.to_i then
			self.errors.add(:account, 'insufficient balance')
		end
	end

	def order_hash_must_be_valid
    calculated_hash = self.class.calculate_hash(self)
		if (!calculated_hash or calculated_hash != order_hash) then
			self.errors.add(:order_hash, 'is invalid')
		end
	end

  # params { :account_address, :give_token_address, :give_amount, :take_token_address, :take_amount, :nonce, :expiry }
  def self.calculate_hash(params)
    exchange_address = ENV['CONTRACT_ADDRESS'].without_checksum
    begin
      encoder = Ethereum::Encoder.new
      encoded_give_amount = encoder.encode("uint", params[:give_amount].to_i)
      encoded_take_amount = encoder.encode("uint", params[:take_amount].to_i)
      encoded_nonce = encoder.encode("uint", params[:nonce].to_i)
      encoded_expiry = encoder.encode("uint", params[:expiry_timestamp_in_milliseconds].to_i)
      payload = exchange_address + params[:account_address].without_prefix + params[:give_token_address].without_prefix + encoded_give_amount + params[:take_token_address].without_prefix + encoded_take_amount + encoded_nonce + encoded_expiry
      result = Eth::Utils.bin_to_prefixed_hex(Eth::Utils.keccak256(Eth::Utils.hex_to_bin(payload)))
    rescue
    end
    return result
  end

  def remove_checksum
    if self.account_address.is_a_valid_address? && self.give_token_address.is_a_valid_address? && self.take_token_address.is_a_valid_address?
      self.account_address = self.account_address.without_checksum
      self.give_token_address = self.give_token_address.without_checksum
      self.take_token_address = self.take_token_address.without_checksum
    end
  end

  def enqueue_update_ticker
    UpdateMarketTickerJob.perform_later(self.market)
  end

  def market_must_be_active
    if !self.market
      return
    end

    if self.market.disabled?
      self.errors.add(:market, 'has been disabled')
    end
  end

  def price_precision_is_valid
    fraction = self.price.to_s.split('.')[1]
    if fraction && fraction.length > 6
      self.errors.add(:price, 'invalid precision')
      # TEMPORARY
      AppLogger.log("invalid price precision, order_hash: #{self.order_hash}")
    end
  end

  def amount_precision_is_valid
    if self.sell
      fraction = self.give_amount.from_wei.split('.')[1]
      if fraction && fraction.length > 2
        self.errors.add(:give_amount, 'invalid precision')
        # TEMPORARY
        AppLogger.log("invalid take_amount precision, order_hash: #{self.order_hash}")
      end
    else
      fraction = self.take_amount.from_wei.split('.')[1]
      if fraction && fraction.length > 2
        self.errors.add(:take_amount, 'invalid precision')
        # TEMPORARY
        AppLogger.log("invalid give_amount precision, order_hash: #{self.order_hash}")
      end
    end
  end
end
