class Refund < ApplicationRecord
  belongs_to :balance

  validate :amount_cannot_be_zero

  before_create :credit_balance
  before_destroy :reverse_balance

  private

    def amount_cannot_be_zero
      if (self.amount.to_i <= 0)
        errors.add(:amount, 'cannot be zero or lower than zero')
      end
    end

    def credit_balance
      self.balance.credit(self.amount)
    end

    def reverse_balance
      self.balance.debit(self.amount)
    end
end
