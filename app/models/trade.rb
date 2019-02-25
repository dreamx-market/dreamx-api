class Trade < ApplicationRecord
	# trade_hash must be valid
	# signature must be valid

	belongs_to :account, class_name: 'Account', foreign_key: 'account_address', primary_key: 'address'	
	belongs_to :order, class_name: 'Order', foreign_key: 'order_hash', primary_key: 'order_hash'

	NON_VALIDATABLE_ATTRS = ["id", "created_at", "updated_at", "uuid"]
  VALIDATABLE_ATTRS = self.attribute_names.reject{|attr| NON_VALIDATABLE_ATTRS.include?(attr)}
  validates_presence_of VALIDATABLE_ATTRS
	validates :amount, numericality: { greater_than: 0 }
	validates :nonce, nonce: true, on: :create
	validate :balance_must_exist_and_is_sufficient, :trade_hash_must_be_valid

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
		exchange_address = Rails.application.config.CONTRACT_ADDRESS
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
end