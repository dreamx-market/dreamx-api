class Balance < ApplicationRecord
	validates_uniqueness_of :account_address, scope: [:token_address]

  validates :balance, :hold_balance, numericality: { :greater_than_or_equal_to => 0 }

  def authentic?
    return (balance_authentic? and hold_balance_authentic?)
  end

  def balance_authentic?
    calculated_balance = total_deposited.to_i + total_traded.to_i - hold_balance.to_i - total_withdrawn.to_i
    return calculated_balance.to_i === balance.to_i
  end

  def hold_balance_authentic?
    return total_volume_held_in_open_orders.to_i === hold_balance.to_i
  end

  def open_orders
    Order.where({ :account_address => account_address, :give_token_address => token_address }).where.not({ status: 'closed' })
  end

  def deposits
    Deposit.where({ :account_address => account_address, :token_address => token_address })
  end

  def withdraws
    Withdraw.where({ :account_address => account_address, :token_address => token_address })
  end

  def closed_and_partially_filled_sell_orders
    Order.where({ :account_address => account_address, :give_token_address => token_address }).where.not({ status: 'open' })
  end

  def closed_and_partially_filled_buy_orders
    Order.where({ :account_address => account_address, :take_token_address => token_address }).where.not({ status: 'open' })
  end

  def sell_trades
    Trade.joins(:order).where( :trades => { :account_address => account_address }, :orders => { :take_token_address => token_address } )
  end

  def buy_trades
    Trade.joins(:order).where( :trades => { :account_address => account_address }, :orders => { :give_token_address => token_address } )
  end

  def total_traded
    total = 0
    closed_and_partially_filled_sell_orders.each do |order|
      total -= order.filled.to_i
    end
    closed_and_partially_filled_buy_orders.each do |order|
      total += order.calculate_take_amount(order.filled)
    end
    sell_trades.each do |trade|
      total -= trade.order.calculate_take_amount(trade.amount)
    end
    buy_trades.each do |trade|
      total += trade.amount.to_i
    end
    return total
  end

  def total_deposited
    total = 0
    deposits.each do |deposit|
      total += deposit.amount.to_i
    end
    return total
  end

  def total_withdrawn
    total = 0
    withdraws.each do |withdraw|
      total += withdraw.amount.to_i
    end
    return total
  end

  def total_volume_held_in_open_orders
    total = 0
    open_orders.each do |order|
      total += (order.give_amount.to_i - order.filled.to_i)
    end
    return total
  end

  def credit(amount)
    balance = balance.to_i + amount.to_i
    save!
  end

  def debit(amount)
    balance = balance.to_i - amount.to_i
    save!
  end

  def hold(amount)
    balance = balance.to_i - amount.to_i
    hold_balance = hold_balance.to_i + amount.to_i
    save!
  end

  def release(amount)
    balance = balance.to_i + amount.to_i
    hold_balance = hold_balance.to_i - amount.to_i
    save!
  end

  def spend(amount)
    hold_balance = hold_balance.to_i - amount.to_i
    save!
  end
end
