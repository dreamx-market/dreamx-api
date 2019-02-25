class Trade < ApplicationRecord
	# amount cannot be 0
	# account must have enough balance
	# nonce cannot be lesser than last nonce
	# order must exist
	# trade_hash must be valid
	# signature must be valid
end
