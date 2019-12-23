class Refund < ApplicationRecord
  belongs_to :balance

  validates :amount, numericality: { greater_than: 0 }

  before_create :credit_balance

  private

    def credit_balance
      balance = self.balance
      balance.with_lock do
        balance.credit(self.amount)
      end
    end
end
