module FraudProtectable
  extend ActiveSupport::Concern

  def validate_balances_integrity(balance)
    if ENV['FRAUD_PROTECTION'] == 'true' and !balance.authentic?
      # debugging only, remove logging before going live
      AppLogger.log("balance ##{balance.id} is unauthentic, balance: #{balance.balance.to_s.from_wei}, real_balance: #{balance.real_balance.to_s.from_wei}, differrence: #{(balance.balance.to_i - balance.real_balance.to_i).to_s.from_wei}")
      errors.add(:balance, 'is compromised')
    end
  end
end