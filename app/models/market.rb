class Market < ApplicationRecord
	belongs_to :base_token, class_name: 'Token', foreign_key: 'base_token_address', primary_key: 'address'
	belongs_to :quote_token, class_name: 'Token', foreign_key: 'quote_token_address', primary_key: 'address'
	validates_uniqueness_of :base_token_address, scope: [:quote_token_address]
	validate :base_and_quote_must_not_equal

	def base_and_quote_must_not_equal
		errors.add(:quote_token_address, 'Quote token address must not equal to base') if base_token_address == quote_token_address
	end
end
