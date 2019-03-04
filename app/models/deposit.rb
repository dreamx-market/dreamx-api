class Deposit < ApplicationRecord
  include FraudProtectable
  
  belongs_to :account, class_name: 'Account', foreign_key: 'account_address', primary_key: 'address'
  belongs_to :token, class_name: 'Token', foreign_key: 'token_address', primary_key: 'address'

  validates :amount, numericality: { greater_than: 0 }
  validate :balances_must_be_authentic, on: :create

  before_create :credit_balance

  private

  def credit_balance
    if (!self.account)
      return
    end

    self.account.balance(self.token_address).credit(self.amount)
  end

  def balances_must_be_authentic
    if (!self.account)
      return
    end

    validate_balances_integrity(self.account.balance(self.token_address))
  end
end
