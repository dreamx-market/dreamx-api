class Account < ApplicationRecord
	has_many :balances, foreign_key: 'account_address', primary_key: 'address'
  has_many :deposits, foreign_key: 'account_address', primary_key: 'address'
  has_many :withdraws, foreign_key: 'account_address', primary_key: 'address'
  has_one :ejection, foreign_key: 'account_address', primary_key: 'address'
	validates :address, uniqueness: true

  before_create :remove_checksum

  class << self
    def initialize_if_not_exist(account_address, token_address)
      self.create({ :address => account_address })
      Balance.create({ :account_address => account_address, :token_address => token_address })
    end
  end

  def balance(token_address)
    Balance.find_by({ :account_address => self.address, :token_address => token_address })
  end

  def eject
    ActiveRecord::Base.transaction do
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
