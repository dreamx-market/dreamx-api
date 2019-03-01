class Withdraw < ApplicationRecord
  belongs_to :account, class_name: 'Account', foreign_key: 'account_address', primary_key: 'address'
  belongs_to :token, class_name: 'Token', foreign_key: 'token_address', primary_key: 'address'

  validates :nonce, nonce: true, on: :create

  validate :balance_must_exist_and_is_sufficient, :amount_must_be_above_minimum

  # amount must be greater than minimum volume
  # withdraw_hash must be valid
  # signature must be valid

  def amount_must_be_above_minimum
    if (!self.token)
      return
    end

    if (self.amount.to_i < self.token.withdraw_minimum.to_i)
      errors.add(:amount, "must be greater than #{self.token.withdraw_minimum.to_ether}")
    end
  end

  def balance_must_exist_and_is_sufficient
    if (!self.account)
      return
    end

    balance = self.account.balances.find_by(token_address: self.token_address)
    if !balance || balance.balance.to_i < self.amount.to_i then
      errors.add(:account_address, 'insufficient balance')
    end
  end
end
