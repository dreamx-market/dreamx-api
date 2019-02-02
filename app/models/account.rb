class Account < ApplicationRecord
	has_many :balances, foreign_key: 'account_address', primary_key: 'address'
	validates :address, uniqueness: true
end
