module FraudProtectable
  extend ActiveSupport::Concern

  def validate_balances_integrity(balance)
    if (!balance_authentic?(balance) or !hold_balance_authentic?(balance))
      p 'COMPROMISED'
    else
      p 'AUTHENTIC'
    end
  end

  def balance_authentic?(balance)
    p balance.total_traded
    # calculated_balance = balance.total_deposited + balance.total_traded - balance.hold_balance - balance.total_withdrawn
    # return calculated_balance === balance.balance.to_i
  end

  def hold_balance_authentic?(balance)
    return balance.total_volume_held_in_open_orders === balance.hold_balance.to_i
  end
end