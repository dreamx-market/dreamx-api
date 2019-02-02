class Order < ApplicationRecord
	# TODO:
  	# balance must exist and is sufficient
  	# market must exist
  	# ecrecover(orderHash, signature) must match with `account`
  	# a transaction to convert balance to hold_balance and save the order atomically and emit a socket event to notify of balance change
	
	validates :give_amount, :take_amount, numericality: { greater_than: 0 }
	validate :nonce_must_be_greater_than_last_nonce, on: :create
	validate :expiry_timestamp_must_be_in_the_future, :balance_must_exist_and_is_sufficient

	private

	def nonce_must_be_greater_than_last_nonce
		if nonce.to_i <= Order.last.nonce.to_i then
			errors.add(:nonce, 'must be greater than last nonce')
		end
	end

	def expiry_timestamp_must_be_in_the_future
		if expiry_timestamp_in_milliseconds.to_i <= Time.now.to_i then
			errors.add(:expiry_timestamp_in_milliseconds, 'must be in the future')
		end
	end

	def balance_must_exist_and_is_sufficient
		balance = Balance.find_by(account_address: account_address, token_address: give_token_address)
		if !balance || balance.balance < give_amount then
			errors.add(:give_amount, 'insufficient balance')
		end
	end
end
