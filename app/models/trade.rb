class Trade < ApplicationRecord
  include AccountNonEjectable

  belongs_to :account, class_name: 'Account', foreign_key: 'account_address', primary_key: 'address'  
	belongs_to :order, class_name: 'Order', foreign_key: 'order_hash', primary_key: 'order_hash'
  has_one :tx, class_name: 'Transaction', as: :transactable

	NON_VALIDATABLE_ATTRS = ["id", "created_at", "updated_at", "gas_fee", "transaction_hash"]
  VALIDATABLE_ATTRS = attribute_names.reject{|attr| NON_VALIDATABLE_ATTRS.include?(attr)}
  validates_presence_of VALIDATABLE_ATTRS
	validates :nonce, uniqueness: true
  validates :trade_hash, signature: true, uniqueness: true
  validate :order_must_be_open, :order_must_have_sufficient_volume, :balance_must_exist_and_is_sufficient, on: :create
  validate :trade_hash_must_be_valid, :volume_must_meet_taker_minimum, :account_must_not_be_ejected

  after_initialize :build_transaction, if: :new_record?
  before_create :remove_checksum, :trade_balances
  after_create :enqueue_update_ticker

  # debugging only, remove logging before going live
  after_create { self.write_log }
  def write_log
    if ENV['RAILS_ENV'] == 'test'
      return
    end
    maker_give_balance = Balance.find_by({ :account_address => maker_address, :token_address => order.give_token_address })
    maker_take_balance = Balance.find_by({ :account_address => maker_address, :token_address => order.take_token_address })
    taker_give_balance = Balance.find_by({ :account_address => taker_address, :token_address => order.give_token_address })
    taker_take_balance = Balance.find_by({ :account_address => taker_address, :token_address => order.take_token_address })
    log_message = %{
      new trade, trade_hash: #{self.trade_hash}
      maker_give_balance: #{maker_give_balance.balance.to_s.from_wei}, maker_give_real_balance: #{maker_give_balance.real_balance.to_s.from_wei}, difference: #{maker_give_balance.balance.to_i - maker_give_balance.real_balance.to_i}
      maker_give_hold_balance: #{maker_give_balance.hold_balance.to_s.from_wei}, maker_give_real_hold_balance: #{maker_give_balance.real_hold_balance.to_s.from_wei}, difference: #{maker_give_balance.hold_balance.to_i - maker_give_balance.real_hold_balance.to_i}
      maker_take_balance: #{maker_take_balance.balance.to_s.from_wei}, maker_take_real_balance: #{maker_take_balance.real_balance.to_s.from_wei}, difference: #{maker_take_balance.balance.to_i - maker_take_balance.real_balance.to_i}
      maker_take_hold_balance: #{maker_take_balance.hold_balance.to_s.from_wei}, maker_take_real_hold_balance: #{maker_take_balance.real_hold_balance.to_s.from_wei}, difference: #{maker_take_balance.hold_balance.to_i - maker_take_balance.real_hold_balance.to_i}
      taker_give_balance: #{taker_give_balance.balance.to_s.from_wei}, taker_give_real_balance: #{taker_give_balance.real_balance.to_s.from_wei}, difference: #{taker_give_balance.balance.to_i - taker_give_balance.real_balance.to_i}
      taker_give_hold_balance: #{taker_give_balance.hold_balance.to_s.from_wei}, taker_give_real_hold_balance: #{taker_give_balance.real_hold_balance.to_s.from_wei}, difference: #{taker_give_balance.hold_balance.to_i - taker_give_balance.real_hold_balance.to_i}
      taker_take_balance: #{taker_take_balance.balance.to_s.from_wei}, taker_take_real_balance: #{taker_take_balance.real_balance.to_s.from_wei}, difference: #{taker_take_balance.balance.to_i - taker_take_balance.real_balance.to_i}
      taker_take_hold_balance: #{taker_take_balance.hold_balance.to_s.from_wei}, taker_take_real_hold_balance: #{taker_take_balance.real_hold_balance.to_s.from_wei}, difference: #{taker_take_balance.hold_balance.to_i - taker_take_balance.real_hold_balance.to_i}
    }
    AppLogger.log(log_message)
  end

  def balance
    self.account.balance(self.order.take_token_address)
  end

  def maker_balance
    self.order.balance
  end

  def taker_balance
    self.balance
  end

  def maker_give_balance
    self.order.account.balance(self.order.give_token_address)
  end

  def maker_take_balance
    self.order.account.balance(self.order.take_token_address)
  end

  def taker_give_balance
    self.account.balance(self.order.give_token_address)
  end

  def taker_take_balance
    self.account.balance(self.order.take_token_address)
  end

  def fee_give_balance
    Balance.fee(self.order.give_token_address)
  end

  def fee_take_balance
    Balance.fee(self.order.take_token_address)
  end

  # used only when a failed transaction is detected
  def refund
    exchange = Contract::Exchange.singleton
    maker_balance = self.order.account.balance(self.order.give_token_address)
    maker_onchain_balance = exchange.balances(self.order.give_token_address, self.order.account_address)
    maker_give_amount = self.order.give_amount.to_i
    maker_difference = maker_give_amount - maker_onchain_balance
    # fake coins removal: if maker is giving more than he has, refund only what he has
    maker_refund_amount = maker_difference > 0 ? maker_give_amount - maker_difference : maker_give_amount
    taker_balance = self.account.balance(self.order.take_token_address)
    taker_onchain_balance = exchange.balances(self.order.take_token_address, self.account_address)
    taker_give_amount = self.amount.to_i
    taker_difference = taker_give_amount - taker_onchain_balance
    # fake coins removal: if taker is giving more than he has, refund only what he has
    taker_refund_amount =  taker_difference > 0 ? taker_give_amount - taker_difference : taker_give_amount
    ActiveRecord::Base.transaction do
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

  def take_amount
    return self.order.calculate_take_amount(self.amount).to_s
  end

  def maker_address
    return self.order.account_address
  end

  def taker_address
    return self.account_address
  end

  def market
    return self.order.market
  end

  def market_symbol
    return self.market.symbol
  end

  def type
    return self.is_sell ? 'sell' : 'buy'
  end

  def is_sell
    return !self.order.is_sell
  end

  def price
    return self.order.price
  end

	def balance_must_exist_and_is_sufficient
		if (!account || !order) then
			return
		end

		balance = account.balances.find_by(token_address: order.take_token_address)
		required_balance = order.calculate_take_amount(amount)
		if !balance || balance.balance.to_i < required_balance.to_i then
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
    if (order.is_sell) then
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

  def trade_balances
    formatter = Ethereum::Formatter.new
    one_ether = formatter.to_wei(1)
    maker_address = order.account_address
    taker_address = account_address
    fee_address = ENV['FEE_COLLECTOR_ADDRESS'].without_checksum
    maker_fee = ENV['MAKER_FEE_PER_ETHER_IN_WEI']
    taker_fee = ENV['TAKER_FEE_PER_ETHER_IN_WEI']
    trade_amount_equivalence_in_take_tokens = order.calculate_take_amount(amount)
    maker_fee_amount = (trade_amount_equivalence_in_take_tokens * maker_fee.to_i) / one_ether.to_i
    taker_fee_amount = (amount.to_i * taker_fee.to_i) / one_ether.to_i

    maker_give_balance = Balance.find_by({ :account_address => maker_address, :token_address => order.give_token_address })
    maker_give_balance.spend(amount)

    taker_give_balance = Balance.find_or_create_by({ :account_address => taker_address, :token_address => order.give_token_address })
    taker_receiving_amount_minus_fee = amount.to_i - taker_fee_amount.to_i
    taker_give_balance.credit(taker_receiving_amount_minus_fee)
    self.fee = taker_fee_amount
    self.maker_fee = maker_fee_amount

    fee_give_balance = Balance.find_or_create_by({ :account_address => fee_address, :token_address => order.give_token_address })
    fee_give_balance.credit(taker_fee_amount)

    maker_take_balance = Balance.find_or_create_by({ :account_address => maker_address, :token_address => order.take_token_address })
    maker_receiveing_amount_minus_fee = trade_amount_equivalence_in_take_tokens - maker_fee_amount.to_i
    maker_take_balance.credit(maker_receiveing_amount_minus_fee)
    order.fill(amount, maker_fee_amount)

    taker_take_balance = Balance.find_by({ :account_address => taker_address, :token_address => order.take_token_address })
    taker_take_balance.debit(trade_amount_equivalence_in_take_tokens)

    fee_take_balance = Balance.find_or_create_by({ :account_address => fee_address, :token_address => order.take_token_address })
    fee_take_balance.credit(maker_fee_amount)

    self.total = self.is_sell ? self.amount : trade_amount_equivalence_in_take_tokens
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
    formatter = Ethereum::Formatter.new
    one_ether = formatter.to_wei(1)
    maker_fee = ENV['MAKER_FEE_PER_ETHER_IN_WEI']
    trade_amount_equivalence_in_take_tokens = self.order.calculate_take_amount(self.amount)
    return (trade_amount_equivalence_in_take_tokens * maker_fee.to_i) / one_ether.to_i
  end

  def calculate_taker_fee
    formatter = Ethereum::Formatter.new
    one_ether = formatter.to_wei(1)
    taker_fee = ENV['TAKER_FEE_PER_ETHER_IN_WEI']
    return (self.amount.to_i * taker_fee.to_i) / one_ether.to_i
  end

  def maker_receiving_amount_after_fee
    trade_amount_equivalence_in_take_tokens = self.order.calculate_take_amount(self.amount)
    return trade_amount_equivalence_in_take_tokens.to_i - self.maker_fee.to_i
  end

  def taker_receiving_amount_after_fee
    return self.amount.to_i - self.taker_fee.to_i
  end

  def give_amount
    self.amount
  end

  def take_amount
    return self.order.calculate_take_amount(self.amount)
  end

  private

  def build_transaction
    self.tx = Transaction.new({ status: 'pending' })
  end  

  def remove_checksum
    self.account_address = self.account_address.without_checksum
  end

  def enqueue_update_ticker
    UpdateMarketTickerJob.perform_later(self.market)
  end
end
