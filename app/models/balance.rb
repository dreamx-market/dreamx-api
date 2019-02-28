class Balance < ApplicationRecord
	validates_uniqueness_of :account_address, scope: [:token_address]

  validates :balance, :hold_balance, numericality: { :greater_than_or_equal_to => 0 }

  def credit(amount)
    self.balance = self.balance.to_i + amount.to_i
    self.save!
  end

  def debit(amount)
    self.balance = self.balance.to_i - amount.to_i
    self.save!
  end

  def hold(amount)
    self.balance = self.balance.to_i - amount.to_i
    self.hold_balance = self.hold_balance.to_i + amount.to_i
    self.save!
  end

  def release(amount)
    self.balance = self.balance.to_i + amount.to_i
    self.hold_balance = self.hold_balance.to_i - amount.to_i
    self.save!
  end

  def spend(amount)
    self.hold_balance = self.hold_balance.to_i - amount.to_i
    self.save!
  end
end
