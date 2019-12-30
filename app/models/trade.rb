class Trade < ApplicationRecord
  include AccountNonEjectable

  belongs_to :account, class_name: 'Account', foreign_key: 'account_address', primary_key: 'address'  
	belongs_to :order, class_name: 'Order', foreign_key: 'order_hash', primary_key: 'order_hash'
  belongs_to :give_balance, class_name: 'Balance', foreign_key: 'give_balance_id', primary_key: 'id'
  belongs_to :take_balance, class_name: 'Balance', foreign_key: 'take_balance_id', primary_key: 'id'
  belongs_to :market, class_name: 'Market', foreign_key: 'market_symbol', primary_key: 'symbol'
  alias_attribute :balance, :take_balance
  has_one :tx, class_name: 'Transaction', as: :transactable

  validates :trade_hash, :nonce, uniqueness: true
  validates :account_address, :order_hash, :amount, :nonce, :trade_hash, :signature, :fee, :total, :maker_fee, presence: true

  validates :trade_hash, signature: true
  validate :order_must_be_open, :order_must_have_sufficient_volume, :balance_must_exist_and_is_sufficient, :account_must_not_be_ejected, on: :create
  validate :trade_hash_must_be_valid, :volume_must_meet_taker_minimum

  before_validation :initialize_attributes, :build_transaction, on: :create
  before_validation :remove_checksum
  before_create :calculate_fees_and_total, :trade_balances_and_fill_order_with_lock
  after_create :enqueue_update_ticker

  class << self
    # TEMPORARY
    def duplicates
      self.select(:nonce).group(:nonce).having("count(*) > 1").size
    end
  end

  def maker_balance
    self.order.balance
  end

  def taker_balance
    self.balance
  end

  def fee_give_balance
    Balance.fee(self.order.give_token_address)
  end

  def fee_take_balance
    Balance.fee(self.order.take_token_address)
  end

  # used by transaction.mark_failed
  def refund
    if !self.persisted?
      raise 'cannot refund unpersisted trades'
    end

    maker_onchain_balance = self.maker_balance.onchain_balance
    maker_giving_amount = self.give_amount
    maker_delta = maker_giving_amount.to_i - maker_onchain_balance.to_i
    # fake coins removal: if maker is giving more than he has, refund only what he has
    maker_refund_amount = maker_delta > 0 ? maker_onchain_balance : maker_giving_amount

    taker_onchain_balance = self.taker_balance.onchain_balance
    taker_giving_amount = self.take_amount
    taker_delta = taker_giving_amount.to_i - taker_onchain_balance.to_i
    # fake coins removal: if taker is giving more than he has, refund only what he has
    taker_refund_amount =  taker_delta > 0 ? taker_onchain_balance : taker_giving_amount

    ActiveRecord::Base.transaction do
      locked_balances = Balance.lock.where({ id: [self.maker_balance.id, self.taker_balance.id] }).includes([:token, :account])
      maker_balance = locked_balances.find { |b| b.account_address == self.maker_address && b.token_address == self.give_token_address }
      taker_balance = locked_balances.find { |b| b.account_address == self.taker_address && b.token_address == self.take_token_address }
      maker_balance.refund(maker_refund_amount)
      taker_balance.refund(taker_refund_amount)
    end
  end

  def transaction_hash
    self.tx ? self.tx.transaction_hash : nil
  end

  def payload
    maker_address = order.account_address
    taker_address = account_address
    give_token = order.give_token_address
    take_token = order.take_token_address
    give_amount = order.give_amount.to_i
    take_amount = order.take_amount.to_i
    fill_amount = amount.to_i
    maker_nonce = order.nonce.to_i
    taker_nonce = nonce.to_i
    maker_fee = ENV['MAKER_FEE_PER_ETHER_IN_WEI'].to_i
    taker_fee = ENV['TAKER_FEE_PER_ETHER_IN_WEI'].to_i
    expiry = order.expiry_timestamp_in_milliseconds.to_i
    maker_v = order.v
    maker_r = order.r
    maker_s = order.s
    taker_v = v
    taker_r = r
    taker_s = s

    exchange = Contract::Exchange.singleton
    fun = exchange.functions('trade')
    addresses = [maker_address, taker_address, give_token, take_token]
    uints = [give_amount, take_amount, fill_amount, maker_nonce, taker_nonce, maker_fee, taker_fee, expiry]
    v = [maker_v, taker_v]
    rs = [maker_r, maker_s, taker_r, taker_s]
    args = [addresses, uints, v, rs]
    exchange.call_payload(fun, args)
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

  def taker_fee
    return self.fee
  end

  def give_token_address
    return self.order.give_token_address
  end

  def take_token_address
    return self.order.take_token_address
  end

  def give_amount
    return self.amount
  end

  def maker_address
    return self.order.account_address
  end

  def taker_address
    return self.account_address
  end

	def balance_must_exist_and_is_sufficient
		if !self.balance || !self.order
			return
		end

		if self.balance.balance.to_i < self.take_amount.to_i
			errors.add(:balance, 'is insufficient')
		end
	end

	def trade_hash_must_be_valid
    calculated_hash = self.class.calculate_hash(self)
		if (!calculated_hash or calculated_hash != self.trade_hash) then
			errors.add(:trade_hash, "is invalid")
		end
	end

  # params { :account_address, :order_hash, :amount, :nonce }
  def self.calculate_hash(params)
    exchange_address = ENV['CONTRACT_ADDRESS'].without_checksum
    begin
      encoder = Ethereum::Encoder.new
      encoded_amount = encoder.encode("uint", params[:amount].to_i)
      encoded_nonce = encoder.encode("uint", params[:nonce].to_i)
      payload = exchange_address + params[:order_hash].without_prefix + params[:account_address].without_prefix + encoded_amount + encoded_nonce
      result = Eth::Utils.bin_to_prefixed_hex(Eth::Utils.keccak256(Eth::Utils.hex_to_bin(payload)))
    rescue
    end
    return result
  end

  def volume
    if (order.sell) then
      return order.take_amount.to_i * amount.to_i / order.give_amount.to_i
    else
      return amount.to_i
    end
  end

  def volume_must_meet_taker_minimum
    if (!order) then
      return
    end

    minimum_volume = ENV['TAKER_MINIMUM_ETH_IN_WEI'].to_i
    if self.volume < minimum_volume
      errors.add(:amount, "must be greater than #{ENV['TAKER_MINIMUM_ETH_IN_WEI']}")
    end
  end

  def maker_give_balance
    self.order.give_balance
  end

  def maker_take_balance
    self.order.take_balance
  end

  def taker_give_balance
    self.give_balance
  end

  def taker_take_balance
    self.take_balance
  end

  def maker_account
    self.order.account
  end

  def taker_account
    self.account
  end

  def trade_balances_and_fill_order_with_lock
    ActiveRecord::Base.transaction do
      maker_account.create_balance_if_not_exist(take_token_address)
      taker_account.create_balance_if_not_exist(give_token_address)
      locked_balances = Balance.lock.where({ account_address: [maker_address, taker_address], token_address: [give_token_address, take_token_address] }).includes([:token, :account])
      maker_give_balance = locked_balances.find { |b| b.account_address == maker_address && b.token_address == give_token_address }
      taker_give_balance = locked_balances.find { |b| b.account_address == taker_address && b.token_address == give_token_address }
      maker_take_balance = locked_balances.find { |b| b.account_address == maker_address && b.token_address == take_token_address }
      taker_take_balance = locked_balances.find { |b| b.account_address == taker_address && b.token_address == take_token_address }
      order = self.order.lock!
      
      maker_give_balance.spend(self.amount)
      maker_take_balance.credit(self.maker_receiving_amount_after_fee)
      taker_give_balance.credit(self.taker_receiving_amount_after_fee)
      taker_take_balance.debit(self.take_amount)
      order.fill(amount, self.maker_fee)
      if order.status == 'closed'
        maker_give_balance.release(order.remaining_give_amount)
      end
    end
  end

  def order_must_be_open
    if self.order
      if self.order.status == 'closed'
        self.errors.add(:order, 'must be open')
      end
    end
  end

  def order_must_have_sufficient_volume
    if self.order
      if self.order.give_amount.to_i < (self.order.filled.to_i + self.amount.to_i)
        self.errors.add(:order, 'must have sufficient volume')
      end
    end
  end

  def calculate_maker_fee
    one_ether = '1'.to_wei.to_i
    maker_fee = ENV['MAKER_FEE_PER_ETHER_IN_WEI'].to_i
    (self.take_amount * maker_fee) / one_ether
  end

  def calculate_taker_fee
    one_ether = '1'.to_wei.to_i
    taker_fee = ENV['TAKER_FEE_PER_ETHER_IN_WEI'].to_i
    (self.amount.to_i * taker_fee) / one_ether
  end

  def maker_receiving_amount_after_fee
    return self.take_amount.to_i - self.maker_fee.to_i
  end

  def taker_receiving_amount_after_fee
    return self.amount.to_i - self.taker_fee.to_i
  end

  def initialize_attributes
    if self.account && self.order
      self.give_balance = self.account.balance(self.order.give_token.address)
      self.take_balance = self.account.balance(self.order.take_token.address)
      self.market = self.order.market
      self.price = self.order.price
      self.sell = !self.order.sell
      self.take_amount = self.order.calculate_take_amount(self.amount).to_i
    end
  end

  private

  def remove_checksum
    if self.account_address.is_a_valid_address?
      self.account_address = self.account_address.without_checksum
    end
  end

  def calculate_fees_and_total
    self.fee = self.calculate_taker_fee
    self.maker_fee = self.calculate_maker_fee
    self.total = self.sell ? self.amount : self.take_amount
  end

  def enqueue_update_ticker
    UpdateMarketTickerJob.perform_later(self.market)
  end

  def build_transaction
    self.tx ||= Transaction.new({ status: 'pending' })
  end
end
