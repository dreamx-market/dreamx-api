class Account < ApplicationRecord
	has_many :balances, foreign_key: 'account_address', primary_key: 'address', dependent: :destroy
  has_many :deposits, foreign_key: 'account_address', primary_key: 'address'
  has_many :withdraws, foreign_key: 'account_address', primary_key: 'address'
  has_one :ejection, foreign_key: 'account_address', primary_key: 'address'
	validates :address, uniqueness: true

  before_create :remove_checksum

  class << self
    def generate_random_address
      "0x#{SecureRandom.hex(20)}"
    end
  end

  def balance(token_address_or_symbol)
    if (!token_address_or_symbol.is_a_valid_address?)
      token = Token.find_by({ symbol: token_address_or_symbol.upcase })
      token_address = token.address
    else
      token_address = token_address_or_symbol
    end

    Balance.find_or_create_by({ :account_address => self.address, :token_address => token_address })
  end

  def create_balance_if_not_exist(token_address_or_symbol)
    self.balance(token_address_or_symbol)
  end

  def eject
    self.with_lock do
      self.close_all_open_orders
      self.ejection = Ejection.new
      self.ejected = true
      self.save!
    end
  end

  def close_all_open_orders
    self.balances.each do |balance|
      balance.open_orders.each do |order|
        order.cancel
      end
    end
  end

  private

  def remove_checksum
    self.address = self.address.without_checksum
  end
end
