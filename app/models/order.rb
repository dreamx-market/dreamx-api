class Order < ApplicationRecord
  include FraudProtectable
  
	belongs_to :account, class_name: 'Account', foreign_key: 'account_address', primary_key: 'address'	
  
	validates :account_address, :give_token_address, :give_amount, :take_token_address, :take_amount, :nonce, :expiry_timestamp_in_milliseconds, :order_hash, :signature, presence: true
	validates :give_amount, :take_amount, numericality: { greater_than: 0 }
	validates :nonce, nonce: true, on: :create
  validates :order_hash, signature: true, uniqueness: true
  validates :filled, numericality: { :greater_than_or_equal_to => 0 }, on: :update

	validate :status_must_be_open_closed_or_partially_filled, :addresses_must_be_valid, :expiry_timestamp_must_be_in_the_future, :market_must_exist, :order_hash_must_be_valid, :filled_must_not_exceed_give_amount
  validate :market_must_be_active, :balances_must_be_authentic, :balance_must_exist_and_is_sufficient, :volume_must_be_greater_than_minimum, on: :create

	before_create :remove_checksum, :hold_balance
  after_create :update_ticker
  after_commit { 
    MarketOrdersRelayJob.perform_later(self) 
    AccountOrdersRelayJob.perform_later(self)
  }
  after_rollback :mark_balance_as_fraud_if_inauthentic

  def mark_balance_as_fraud_if_inauthentic
    if ENV['FRAUD_PROTECTION'] == 'true' and !balance.authentic?
      self.balance.mark_fraud!
      Config.set('read_only', 'true')
    end
  end

  def balance
    self.account.balance(self.give_token_address)
  end

  def has_sufficient_remaining_volume?
    if (self.is_sell) then
      attribute = :take_amount
      remaining_volume = self.take_amount.to_i - self.calculate_take_amount(self.filled.to_i)
    else
      attribute = :give_amount
      remaining_volume = self.give_amount.to_i - self.filled.to_i
    end
    minimum_volume = ENV['TAKER_MINIMUM_ETH_IN_WEI'].to_i
    return remaining_volume >= minimum_volume
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

  def market
    return Market.find_by({ :base_token_address => self.take_token_address, :quote_token_address => self.give_token_address }) || Market.find_by({ :base_token_address => self.give_token_address, :quote_token_address => self.take_token_address })
  end

  def market_symbol
    return self.market.symbol
  end

  def calculate_take_amount(give_amount)
    give_amount = Money.new(give_amount)
    take_amount = give_amount * self.take_amount.to_i / self.give_amount.to_i
    return take_amount.fractional
  end

  def calculate_give_amount(take_amount)
    take_amount = Money.new(take_amount)
    give_amount = take_amount * self.give_amount.to_i / self.take_amount.to_i
    return give_amount.fractional
  end

  def price
    if (is_sell)
      (self.take_amount.to_f / self.give_amount.to_f)
    else
      (self.give_amount.to_f / self.take_amount.to_f)
    end
  end

  def is_sell
    self.take_token_address == "0x0000000000000000000000000000000000000000" ? true : false
  end

  def fill(amount, fee)
    self.filled = self.filled.to_i + amount.to_i
    self.fee = self.fee.to_i + fee.to_i

    if self.filled.to_i == self.give_amount.to_i or !self.has_sufficient_remaining_volume? then
      self.status = 'closed'
    else
      self.status = 'partially_filled'
    end

    self.save!
  end

  def cancel
    remaining = self.give_amount.to_i - self.filled.to_i
    self.account.balance(self.give_token_address).release(remaining)
    self.status = 'closed'
    self.save!
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
		balance = self.account.balances.find_by(token_address: give_token_address)
		if !balance || balance.balance.to_i < give_amount.to_i then
			errors.add(:account_address, 'insufficient balance')
		end
	end

	def market_must_exist
		market = Market.find_by(:base_token_address => take_token_address, :quote_token_address => give_token_address) || Market.find_by(:base_token_address => give_token_address, :quote_token_address => take_token_address)
		if (!market) then
			errors.add(:market, 'market does not exist')
		end
	end

	def order_hash_must_be_valid
    calculated_hash = self.class.calculate_hash(self)
		if (!calculated_hash or calculated_hash != order_hash) then
			errors.add(:order_hash, "invalid")
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
				errors.add(key, "invalid #{key.to_s}")
			end
		end
	end

	def hold_balance
		balance = self.account.balances.find_by(:token_address => give_token_address)
		balance.balance = balance.balance.to_i - give_amount.to_i
		balance.hold_balance = balance.hold_balance.to_i + give_amount.to_i
		balance.save
	end

  def volume_must_be_greater_than_minimum
    if (self.is_sell) then
      attribute = :take_amount
      volume = self.take_amount.to_i
    else
      attribute = :give_amount
      volume = self.give_amount.to_i
    end

    minimum_volume = ENV['MAKER_MINIMUM_ETH_IN_WEI'].to_i
    errors.add(attribute, "must be greater than #{minimum_volume}") unless volume >= minimum_volume
  end

  def balances_must_be_authentic
    if (!self.account)
      return
    end
    
    validate_balances_integrity(self.account.balance(self.give_token_address))
  end

  def remove_checksum
    self.account_address = self.account_address.without_checksum
    self.give_token_address = self.give_token_address.without_checksum
    self.take_token_address = self.take_token_address.without_checksum
  end

  def update_ticker
    self.market.ticker.update_data
  end  

  def market_must_be_active
    if self.market.disabled?
      self.errors.add(:market, 'has been disabled')
    end
  end
end
