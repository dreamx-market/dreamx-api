class Order < ApplicationRecord
	# TODO:
  	# validate signature, ecrecover(orderHash, signature) must match with `account`
  	# a transaction to convert balance to hold_balance and save the order atomically and emit a socket event to notify of balance change
	
	validates :account_address, :give_token_address, :give_amount, :take_token_address, :take_amount, :nonce, :expiry_timestamp_in_milliseconds, :order_hash, :signature, presence: true
	validates :give_amount, :take_amount, numericality: { greater_than: 0 }
	validate :nonce_must_be_greater_than_last_nonce, on: :create
	validate :addresses_must_be_valid, :expiry_timestamp_must_be_in_the_future, :balance_must_exist_and_is_sufficient, :market_must_exist, :order_hash_must_be_valid

	private

	def nonce_must_be_greater_than_last_nonce
		if Order.last && nonce.to_i <= Order.last.nonce.to_i then
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
		if !balance || balance.balance.to_i < give_amount.to_i then
			errors.add(:give_amount, 'insufficient balance')
		end
	end

	def market_must_exist
		market = Market.find_by(:base_token_address => take_token_address, :quote_token_address => give_token_address) || Market.find_by(:base_token_address => give_token_address, :quote_token_address => take_token_address)
		if (!market) then
			errors.add(:market, 'market does not exist')
		end
	end

	def order_hash_must_be_valid
		exchange_address = Rails.application.config.CONTRACT_ADDRESS
	 	begin
	 		encoder = Ethereum::Encoder.new
	 		encoded_give_amount = encoder.encode("uint", give_amount.to_i)
			encoded_take_amount = encoder.encode("uint", take_amount.to_i)
			encoded_nonce = encoder.encode("uint", nonce.to_i)
			encoded_expiry = encoder.encode("uint", expiry_timestamp_in_milliseconds.to_i)
			payload = exchange_address + account_address.without_prefix + give_token_address.without_prefix + encoded_give_amount + take_token_address.without_prefix + encoded_take_amount + encoded_nonce + encoded_expiry
      result = Eth::Utils.bin_to_prefixed_hex(Eth::Utils.keccak256(Eth::Utils.hex_to_bin(payload)))
    rescue
    end
		if (!result or result != order_hash) then
			errors.add(:order_hash, "invalid order_hash")
		end
	end

	def addresses_must_be_valid
		[:account_address, :give_token_address, :take_token_address].each do |key|
			if !Eth::Address.new(eval(key.to_s)).valid? then
				errors.add(key, "invalid #{key.to_s}")
			end
		end
	end
end
