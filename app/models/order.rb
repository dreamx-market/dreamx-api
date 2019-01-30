class Order < ApplicationRecord
	# account must have a sufficient balance
	# 0 amounts aren't acceptable
	# market must exist
	# nonce must be greater than last nonce
	# expiry timestamps must be in the future
	# ecrecover(orderHash, signature) must equal to account
end
