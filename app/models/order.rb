class Order < ApplicationRecord
  include AccountNonEjectable

  has_many :trades, foreign_key: 'order_hash', primary_key: 'order_hash'  
  has_one :give_token, class_name: 'Token', foreign_key: 'address', primary_key: 'give_token_address'
  has_one :take_token, class_name: 'Token', foreign_key: 'address', primary_key: 'take_token_address'
	belongs_to :account, class_name: 'Account', foreign_key: 'account_address', primary_key: 'address'	
  belongs_to :give_balance, class_name: 'Balance', foreign_key: 'give_balance_id', primary_key: 'id'
  belongs_to :take_balance, class_name: 'Balance', foreign_key: 'take_balance_id', primary_key: 'id'
  belongs_to :market, class_name: 'Market', foreign_key: 'market_symbol', primary_key: 'symbol'
  alias_attribute :balance, :give_balance
  
  validates :order_hash, :nonce, uniqueness: true
  validates :account_address, :give_token_address, :give_amount, :take_token_address, :take_amount, :nonce, :expiry_timestamp_in_milliseconds, :order_hash, :signature, presence: true
  
	validates :give_amount, :take_amount, numericality: { greater_than: 0 }
  validates :order_hash, signature: true
  validates :filled, numericality: { :greater_than_or_equal_to => 0 }
  validates :filled, numericality: { :equal_to => 0 }, on: :create
  validate :status_must_be_open_on_create, on: :create
	validate :status_must_be_open_closed_or_partially_filled, :addresses_must_be_valid, :expiry_timestamp_must_be_in_the_future, :order_hash_must_be_valid, :filled_must_not_exceed_give_amount, :account_must_not_be_ejected
  validate :market_must_be_active, :balance_must_exist_and_is_sufficient, :volume_must_meet_maker_minimum, on: :create

  before_validation :initialize_attributes, on: :create
  before_validation :remove_checksum
	before_create :hold_balance_with_lock
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
    # TEMPORARY
    def duplicates
      self.select(:nonce).group(:nonce).having("count(*) > 1").size
    end
  end

  def status_must_be_open_on_create
    if self.status != 'open'
      errors.add(:status, 'must be open')
    end
  end

  def remaining_give_amount
    self.give_amount.to_i - self.filled.to_i
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

  # order altering operations

  def fill(amount, fee=0)
    self.filled = self.filled.to_i + amount.to_i
    self.fee = self.fee.to_i + fee.to_i

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
    if self.remaining_volume < minimum_volume
      errors.add(attribute, "must be greater than #{minimum_volume}")
    end
  end

  def remaining_volume_is_above_taker_minimum?
    minimum_volume = ENV['TAKER_MINIMUM_ETH_IN_WEI'].to_i
    return self.remaining_volume >= minimum_volume
  end

  def hold_balance_with_lock
    balance = self.balance
    balance.with_lock do
      balance.hold(give_amount)
    end
  end

  def initialize_attributes
    if self.account && 
      self.give_token_address.is_a_valid_address? && 
      self.take_token_address.is_a_valid_address? then
      self.give_balance = self.account.balance(self.give_token_address)
      self.take_balance = self.account.balance(self.take_token_address)
      self.market = Market.find_by({ :base_token_address => self.take_token_address, :quote_token_address => self.give_token_address }) || Market.find_by({ :base_token_address => self.give_token_address, :quote_token_address => self.take_token_address })
    end

    if self.market
      self.sell = self.give_token_address == self.market.base_token_address ? false : true
    end

    if (self.sell)
      self.price = self.take_amount.to_d / self.give_amount.to_d
    else
      self.price = self.give_amount.to_d / self.take_amount.to_d
    end
  end

  def filled_take_minus_fee
    self.calculate_take_amount(self.filled).to_i - self.fee.to_i
  end

	private

  def status_must_be_open_closed_or_partially_filled
    if !['open', 'closed', 'partially_filled'].include?(self.status)
      errors.add(:status, 'must be open, closed or partially_filled')
    end
  end

  def filled_must_not_exceed_give_amount
    errors.add(:filled, 'must not exceed give_amount') unless filled.to_i <= give_amount.to_i
  end

	def expiry_timestamp_must_be_in_the_future
		if expiry_timestamp_in_milliseconds.to_i <= Time.now.to_i then
			errors.add(:expiry_timestamp_in_milliseconds, 'must be in the future')
		end
	end

	def balance_must_exist_and_is_sufficient
		if !self.balance || self.balance.reload.balance.to_i < give_amount.to_i then
			errors.add(:account, 'insufficient balance')
		end
	end

	def order_hash_must_be_valid
    calculated_hash = self.class.calculate_hash(self)
		if (!calculated_hash or calculated_hash != order_hash) then
			errors.add(:order_hash, 'is invalid')
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

	def addresses_must_be_valid
		[:account_address, :give_token_address, :take_token_address].each do |key|
			if !Eth::Address.new(eval(key.to_s)).valid? then
				errors.add(key, 'is invalid')
			end
		end
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
end
