class Refund < ApplicationRecord
  belongs_to :balance

  before_create :credit_balance

  private

    def credit_balance
      self.balance.credit(self.amount)
    end
end
