class Account < ApplicationRecord
	has_many :balances, foreign_key: 'account_address', primary_key: 'address'
  has_many :deposits, foreign_key: 'account_address', primary_key: 'address'
  has_many :withdraws, foreign_key: 'account_address', primary_key: 'address'
	validates :address, uniqueness: true

  # before_create :remove_checksum

  def balance(token_address)
    Balance.find_by({ :account_address => self.address, :token_address => token_address })
  end

  def self.initialize_if_not_exist(account_address, token_address)
    self.create({ :address => account_address })
    Balance.create({ :account_address => account_address, :token_address => token_address })
  end

  private

  def remove_checksum
    self.address = self.address.without_checksum
  end
end
