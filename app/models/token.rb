class Token < ApplicationRecord
	has_many :markets, foreign_key: 'base_token_address'
end
