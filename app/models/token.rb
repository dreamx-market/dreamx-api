class Token < ApplicationRecord
	has_many :markets, foreign_key: 'base_token_address', primary_key: 'address'
	validates :address, uniqueness: true
	validates :name, uniqueness: true
	validates :symbol, uniqueness: true
end
