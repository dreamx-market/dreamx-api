class Trade < ApplicationRecord
	# account must have enough balance
	# nonce cannot be lesser than last nonce
	# order_hash must exist
	# trade_hash must be valid
	# signature must be valid

	belongs_to :account, class_name: 'Account', foreign_key: 'account_address', primary_key: 'address'	
	belongs_to :order, class_name: 'Order', foreign_key: 'order_hash', primary_key: 'order_hash'
	validates :amount, numericality: { greater_than: 0 }
	validate :balance_must_exist_and_is_sufficient

	def balance_must_exist_and_is_sufficient
		balance = self.account.balances.find_by(token_address: self.order.take_token_address)
		required_balance = (self.order.take_amount.to_i * amount.to_i) / self.order.give_amount.to_i
		if !balance || balance.balance.to_i < required_balance.to_i then
			errors.add(:account_address, 'insufficient balance')
		end
	end
end
