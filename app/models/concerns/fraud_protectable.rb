module FraudProtectable
  extend ActiveSupport::Concern

  def validate_balances_integrity(balance)
    if ENV['FRAUD_PROTECTION'] == 'true' and !balance.authentic?
      # debugging only, remove logging before going live
      AppLogger.log("balance ##{balance.id} is unauthentic, balance: #{balance.balance}, real_balance: #{balance.real_balance}, differrence: #{balance.balance.to_i - balance.real_balance.to_i}")
      errors.add(:balance, 'is compromised')
    end
  end
end