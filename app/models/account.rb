class Account < ApplicationRecord
	has_many :balances, foreign_key: 'account_address', primary_key: 'address'
	validates :address, uniqueness: true

  def balance(token_address)
    Balance.find_by({ :account_address => self.address, :token_address => token_address })
  end
end
