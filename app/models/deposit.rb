class Deposit < ApplicationRecord
  belongs_to :account, class_name: 'Account', foreign_key: 'account_address', primary_key: 'address'
  belongs_to :token, class_name: 'Token', foreign_key: 'token_address', primary_key: 'address'

  validates :amount, numericality: { greater_than: 0 }

  before_create :credit_balance

  private

  def credit_balance
    self.account.balance(self.token_address).credit(self.amount)
  end
end
