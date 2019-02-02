class Balance < ApplicationRecord
	validates_uniqueness_of :account_address, scope: [:token_address]
end
