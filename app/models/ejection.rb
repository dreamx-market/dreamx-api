class Ejection < ApplicationRecord
  belongs_to :account

  validates :account_address, uniqueness: true

  before_validation :initialize_attributes, :lock_attributes, on: :create
  before_validation :remove_checksum
  before_create :eject_account

  class << self
    def aggregate(from, to=from)
      exchange = Contract::Exchange.singleton
      ejections = exchange.ejections(from, to)
      ejections.each do |ejection|
        account = Account.find_by(address: ejection[:account].without_checksum)
        if !account
          next
        end
        new_ejection = Ejection.new({ 
          account_address: account.address, 
          transaction_hash: ejection[:transaction_hash],
          block_number: ejection[:block_number]
        })
        new_ejection.save!
      end
    end
  end

  def eject_account
    self.account.open_orders.each do |order|
      order.balance.release(order.remaining_give_amount)
      order.cancel
    end
    self.account.eject
  end

  def initialize_attributes
    self.account = Account.find_by(address: self.account_address)
  end

  private

  def lock_attributes
    if self.account
      self.account.lock!
      self.account.balances.lock!
      self.account.open_orders.lock!
    end
  end

  def remove_checksum
    if self.account_address.is_a_valid_address?
      self.account_address = self.account_address.without_checksum
    end
  end
end
