class Balance < ApplicationRecord
	validates_uniqueness_of :account_address, scope: [:token_address]

  validates :balance, :hold_balance, numericality: { :greater_than_or_equal_to => 0 }
end
