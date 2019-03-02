class Balance < ApplicationRecord
	validates_uniqueness_of :account_address, scope: [:token_address]

  validates :balance, :hold_balance, numericality: { :greater_than_or_equal_to => 0 }

  def deposits
    Deposit.where({ :account_address => self.account_address, :token_address => self.token_address })
  end

  def withdraws
    Withdraw.where({ :account_address => self.account_address, :token_address => self.token_address })
  end

  def closed_and_partially_filled_sell_orders
    Order.where({ :account_address => self.account_address, :give_token_address => self.token_address }).where.not({ status: 'open' })
  end

  def closed_and_partially_filled_buy_orders
    Order.where({ :account_address => self.account_address, :take_token_address => self.token_address }).where.not({ status: 'open' })
  end

  def sell_trades
    Trade.joins(:order).where( :trades => { :account_address => self.account_address }, :orders => { :take_token_address => self.token_address } )
  end

  def buy_trades
    Trade.joins(:order).where( :trades => { :account_address => self.account_address }, :orders => { :give_token_address => self.token_address } )
  end

  def total_traded
    total = 0
    # WRONG MATH
    self.closed_and_partially_filled_sell_orders.each do |order|
      total -= order.filled.to_i
    end
    self.closed_and_partially_filled_buy_orders.each do |order|
      total += order.filled.to_i
    end
    self.sell_trades.each do |trade|
      total -= trade.amount.to_i
    end
    self.buy_trades.each do |trade|
      total += trade.amount.to_i
    end
    return total
  end

  def total_deposited
    total = 0
    self.deposits.each do |deposit|
      total += deposit.amount.to_i
    end
    return total
  end

  def total_withdrawn
    total = 0
    balance.withdraws.each do |withdraw|
      total += withdraw.amount.to_i
    end
    return total
  end

  def total_volume_held_in_open_orders
    total = 0
    self.open_orders.each do |order|
      total += (order.give_amount.to_i - order.filled.to_i)
    end
    return total
  end

  def credit(amount)
    self.balance = self.balance.to_i + amount.to_i
    self.save!
  end

  def debit(amount)
    self.balance = self.balance.to_i - amount.to_i
    self.save!
  end

  def hold(amount)
    self.balance = self.balance.to_i - amount.to_i
    self.hold_balance = self.hold_balance.to_i + amount.to_i
    self.save!
  end

  def release(amount)
    self.balance = self.balance.to_i + amount.to_i
    self.hold_balance = self.hold_balance.to_i - amount.to_i
    self.save!
  end

  def spend(amount)
    self.hold_balance = self.hold_balance.to_i - amount.to_i
    self.save!
  end
end
