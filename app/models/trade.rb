class Trade < ApplicationRecord
  include FraudProtectable

	belongs_to :account, class_name: 'Account', foreign_key: 'account_address', primary_key: 'address'	
	belongs_to :order, class_name: 'Order', foreign_key: 'order_hash', primary_key: 'order_hash'

	NON_VALIDATABLE_ATTRS = ["id", "created_at", "updated_at", "uuid"]
  VALIDATABLE_ATTRS = self.attribute_names.reject{|attr| NON_VALIDATABLE_ATTRS.include?(attr)}
  validates_presence_of VALIDATABLE_ATTRS
	validates :nonce, nonce: true, on: :create
  validates :trade_hash, signature: true

	validate :balance_must_exist_and_is_sufficient, :trade_hash_must_be_valid, :volume_must_be_greater_than_minimum
  validate :balances_must_be_authentic, on: :create

  before_create :trade_balances

	def balance_must_exist_and_is_sufficient
		if (!self.account || !self.order) then
			return
		end

		balance = self.account.balances.find_by(token_address: self.order.take_token_address)
		required_balance = (self.order.take_amount.to_i * amount.to_i) / self.order.give_amount.to_i
		if !balance || balance.balance.to_i < required_balance.to_i then
			errors.add(:account_address, 'insufficient balance')
		end
	end

	def trade_hash_must_be_valid
		exchange_address = ENV['CONTRACT_ADDRESS']
	 	begin
	 		encoder = Ethereum::Encoder.new
	 		encoded_amount = encoder.encode("uint", amount.to_i)
			encoded_nonce = encoder.encode("uint", nonce.to_i)
			payload = exchange_address + order_hash.without_prefix + account_address.without_prefix + encoded_amount + encoded_nonce
      result = Eth::Utils.bin_to_prefixed_hex(Eth::Utils.keccak256(Eth::Utils.hex_to_bin(payload)))
    rescue
    end
		if (!result or result != trade_hash) then
			errors.add(:trade_hash, "invalid")
		end
	end

  def volume_must_be_greater_than_minimum
    if (!self.order) then
      return
    end

    if (self.order.is_sell) then
      volume = self.order.take_amount.to_i * self.amount.to_i / self.order.give_amount.to_i
    else
      volume = self.amount.to_i
    end

    minimum_volume = ENV['TAKER_MINIMUM_ETH_IN_WEI'].to_i
    errors.add(:amount, "must be greater than #{ENV['TAKER_MINIMUM_ETH_IN_WEI']}") unless volume >= minimum_volume
  end

  def trade_balances
    formatter = Ethereum::Formatter.new
    one_ether = formatter.to_wei(1)
    maker_address = self.order.account_address
    taker_address = self.account_address
    fee_address = ENV['FEE_COLLECTOR_ADDRESS']
    maker_fee = ENV['MAKER_FEE_PER_ETHER_IN_WEI']
    taker_fee = ENV['TAKER_FEE_PER_ETHER_IN_WEI']
    maker_fee_amount = (((self.amount.to_i * self.order.take_amount.to_i) / self.order.give_amount.to_i) * maker_fee.to_i) / one_ether.to_i
    taker_fee_amount = (self.amount.to_i * taker_fee.to_i) / one_ether.to_i
    trade_amount_equivalence_in_take_tokens = (self.amount.to_i * self.order.take_amount.to_i) / self.order.give_amount.to_i

    maker_give_balance = Balance.find_by({ :account_address => maker_address, :token_address => self.order.give_token_address })
    maker_give_balance.spend(self.amount)

    taker_give_balance = Balance.find_by({ :account_address => taker_address, :token_address => self.order.give_token_address })
    taker_receiving_amount_minus_fee = self.amount.to_i - taker_fee_amount.to_i
    taker_give_balance.credit(taker_receiving_amount_minus_fee)
    self.fee = taker_fee_amount

    fee_give_balance = Balance.find_by({ :account_address => fee_address, :token_address => self.order.give_token_address })
    fee_give_balance.credit(taker_fee_amount)

    maker_take_balance = Balance.find_by({ :account_address => maker_address, :token_address => self.order.take_token_address })
    maker_receiveing_amount_minus_fee = trade_amount_equivalence_in_take_tokens - maker_fee_amount.to_i
    maker_take_balance.credit(maker_receiveing_amount_minus_fee)
    self.order.fill(self.amount, maker_fee_amount)

    taker_take_balance = Balance.find_by({ :account_address => taker_address, :token_address => self.order.take_token_address })
    taker_take_balance.debit(trade_amount_equivalence_in_take_tokens)

    fee_take_balance = Balance.find_by({ :account_address => fee_address, :token_address => self.order.take_token_address })
    fee_take_balance.credit(maker_fee_amount)
  end

  def balances_must_be_authentic
    validate_balances_integrity(self.account.balance(self.order.take_token_address))
  end
end
