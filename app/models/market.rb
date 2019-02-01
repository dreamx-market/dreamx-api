class Market < ApplicationRecord
	belongs_to :base_token, class_name: 'Token', foreign_key: 'base_token_address', primary_key: 'address'
	belongs_to :quote_token, class_name: 'Token', foreign_key: 'quote_token_address', primary_key: 'address'
end
