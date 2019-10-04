class Trade < ApplicationRecord
  include FraudProtectable

  belongs_to :account, class_name: 'Account', foreign_key: 'account_address', primary_key: 'address'  
	belongs_to :order, class_name: 'Order', foreign_key: 'order_hash', primary_key: 'order_hash'
  has_one :tx, class_name: 'Transaction', as: :transactable

	NON_VALIDATABLE_ATTRS = ["id", "created_at", "updated_at", "uuid", "gas_fee", "transaction_hash"]
  VALIDATABLE_ATTRS = attribute_names.reject{|attr| NON_VALIDATABLE_ATTRS.include?(attr)}
  validates_presence_of VALIDATABLE_ATTRS
	validates :nonce, nonce: true, on: :create
  validates :trade_hash, signature: true, uniqueness: true
  validate :market_must_be_active, :order_must_be_open, :order_must_have_sufficient_volume, :balances_must_be_authentic, :balance_must_exist_and_is_sufficient, on: :create
  validate :trade_hash_must_be_valid, :volume_must_be_greater_than_minimum

  before_create :remove_checksum, :trade_balances, :generate_transaction
  after_create :update_ticker
  after_rollback :mark_balance_as_fraud_if_inauthentic

  def mark_balance_as_fraud_if_inauthentic
    if ENV['FRAUD_PROTECTION'] == 'true' and !balance.authentic?
      self.balance.mark_fraud!
      Config.set('read_only', 'true')
    end
  end

  def balance
    self.account.balance(self.order.take_token_address)
  end

  def refund
    exchange = Contract::Exchange.singleton.instance
    maker_balance = self.order.account.balance(self.order.give_token_address)
    maker_onchain_balance = exchange.call.balances(self.order.give_token_address, self.order.account_address)
    maker_give_amount = self.order.give_amount.to_i
    maker_difference = maker_give_amount - maker_onchain_balance
    # if maker is giving more than he has, refund only what he has
    maker_refund_amount = maker_difference > 0 ? maker_give_amount - maker_difference : maker_give_amount
    taker_balance = self.account.balance(self.order.take_token_address)
    taker_onchain_balance = exchange.call.balances(self.order.take_token_address, self.account_address)
    taker_give_amount = self.amount.to_i
    taker_difference = taker_give_amount - taker_onchain_balance
    # if taker is giving more than he has, refund only what he has
    taker_refund_amount =  taker_difference > 0 ? taker_give_amount - taker_difference : taker_give_amount
    ActiveRecord::Base.transaction do
      maker_balance.credit(maker_refund_amount)
      taker_balance.credit(taker_refund_amount)
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
    fun = exchange.instance.parent.functions.select { |fun| fun.name == 'trade'}.first
    addresses = [maker_address, taker_address, give_token, take_token]
    uints = [give_amount, take_amount, fill_amount, maker_nonce, taker_nonce, maker_fee, taker_fee, expiry]
    v = [maker_v, taker_v]
    rs = [maker_r, maker_s, taker_r, taker_s]
    args = [addresses, uints, v, rs]
    exchange.instance.parent.call_payload(fun, args)
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
			errors.add(:account_address, 'insufficient balance')
		end
	end

	def trade_hash_must_be_valid
    calculated_hash = self.class.calculate_hash(self)
		if (!calculated_hash or calculated_hash != self.trade_hash) then
			errors.add(:trade_hash, "invalid")
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

  def volume_must_be_greater_than_minimum
    if (!order) then
      return
    end

    if (order.is_sell) then
      volume = order.take_amount.to_i * amount.to_i / order.give_amount.to_i
    else
      volume = amount.to_i
    end

    minimum_volume = ENV['TAKER_MINIMUM_ETH_IN_WEI'].to_i
    errors.add(:amount, "must be greater than #{ENV['TAKER_MINIMUM_ETH_IN_WEI']}") unless volume >= minimum_volume
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

    Account.initialize_if_not_exist(taker_address, order.give_token_address)
    taker_give_balance = Balance.find_by({ :account_address => taker_address, :token_address => order.give_token_address })
    taker_receiving_amount_minus_fee = amount.to_i - taker_fee_amount.to_i
    taker_give_balance.credit(taker_receiving_amount_minus_fee)
    self.fee = taker_fee_amount
    self.maker_fee = maker_fee_amount

    Account.initialize_if_not_exist(fee_address, order.give_token_address)
    fee_give_balance = Balance.find_by({ :account_address => fee_address, :token_address => order.give_token_address })
    fee_give_balance.credit(taker_fee_amount)

    Account.initialize_if_not_exist(maker_address, order.take_token_address)
    maker_take_balance = Balance.find_by({ :account_address => maker_address, :token_address => order.take_token_address })
    maker_receiveing_amount_minus_fee = trade_amount_equivalence_in_take_tokens - maker_fee_amount.to_i
    maker_take_balance.credit(maker_receiveing_amount_minus_fee)
    order.fill(amount, maker_fee_amount)

    taker_take_balance = Balance.find_by({ :account_address => taker_address, :token_address => order.take_token_address })
    taker_take_balance.debit(trade_amount_equivalence_in_take_tokens)

    Account.initialize_if_not_exist(fee_address, order.take_token_address)
    fee_take_balance = Balance.find_by({ :account_address => fee_address, :token_address => order.take_token_address })
    fee_take_balance.credit(maker_fee_amount)

    self.total = self.is_sell ? self.amount : trade_amount_equivalence_in_take_tokens
  end

  def balances_must_be_authentic
    if (!self.account or !self.order)
      return
    end

    validate_balances_integrity(account.balance(order.take_token_address))
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

  private

  def generate_transaction
    self.tx = Transaction.new({ status: 'pending' })
  end  

  def remove_checksum
    self.account_address = self.account_address.without_checksum
  end

  def update_ticker
    self.market.ticker.update_data
  end

  def market_must_be_active
    if self.order
      if self.market.disabled?
        self.errors.add(:market, 'has been disabled')
      end
    end
  end
end
