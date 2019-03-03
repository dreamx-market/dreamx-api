module FraudProtectable
  extend ActiveSupport::Concern

  def validate_balances_integrity(balance)
    if !balance.authentic?
      errors.add(:balance, 'is compromised')
    end
  end
end