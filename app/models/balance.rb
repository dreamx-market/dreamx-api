class Balance < ApplicationRecord
  include Loggable

  has_many :refunds, dependent: :destroy
  belongs_to :token, class_name: 'Token', foreign_key: 'token_address', primary_key: 'address'  

	validates_uniqueness_of :account_address, scope: [:token_address]
  validates :balance, :hold_balance, numericality: { :greater_than_or_equal_to => 0 }

  before_create :remove_checksum
  after_commit { AccountBalancesRelayJob.perform_later(self) }

  class << self
    def has_unauthentic_balances?
      self.all.each do |b|
        if !b.authentic?
          return true
        end
      end

      return false
    end

    def fee_collector(token_address)
      fee_address = ENV['FEE_COLLECTOR_ADDRESS'].without_checksum
      Account.initialize_if_not_exist(fee_address, token_address)
      self.find_by({ :account_address => fee_address, :token_address => token_address })
    end

    def bot(token_symbol)
      account_address = '0x53888c09d2E2a071D8EE6b4b1cA400C9201eE9E7'.without_checksum
      token_address = Token.find_by({ symbol: token_symbol.upcase }).address
      return Balance.find_by({ account_address: account_address, token_address: token_address })
    end
  end

  def offchain_onchain_difference
    self.total_balance.to_i - self.onchain_balance.to_i
  end

  def onchain_balance
    exchange = Contract::Exchange.singleton.instance
    onchain_balance = exchange.call.balances(self.token_address, self.account_address)
    return onchain_balance.to_s
  end

  def mark_fraud!
    self.fraud = true
    self.save!
    # debugging only, remove logging before going live
    self.log("marked balance ##{self.id} as fraud")
    self.log("-----------------")
  end

  def authentic?
    fee_address = ENV['FEE_COLLECTOR_ADDRESS'].without_checksum
    if (fee_address == self.account_address)
      return true
    end

    return (balance_authentic? and hold_balance_authentic?)
  end

  def balance_authentic?
    return self.real_balance.to_i == self.balance.to_i
  end

  def real_balance
    total_deposited.to_i + total_traded.to_i + total_refunded.to_i - hold_balance.to_i - total_withdrawn.to_i
  end

  def real_hold_balance
    self.total_volume_held_in_open_orders
  end

  def total_balance
    self.balance.to_i + self.hold_balance.to_i
  end

  def hold_balance_authentic?
    return total_volume_held_in_open_orders.to_i == hold_balance.to_i
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
      order.trades.each do |trade|
        total += (order.calculate_take_amount(trade.amount).to_i - trade.maker_fee.to_i)
      end
    end
    sell_trades.each do |trade|
      total -= trade.order.calculate_take_amount(trade.amount)
    end
    buy_trades.each do |trade|
      total += (trade.amount.to_i - trade.fee.to_i)
    end
    return total
  end

  def total_refunded
    total = 0
    self.refunds.each do |refund|
      total += refund.amount.to_i
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
    self.open_orders.each do |order|
      total += (order.give_amount.to_i - order.filled.to_i)
    end
    return total
  end

  def refund(amount)
    self.refunds.create({ amount: amount })
  end

  def credit(amount)
    self.balance = balance.to_i + amount.to_i
    save!
  end

  def debit(amount)
    self.balance = balance.to_i - amount.to_i
    save!
  end

  def hold(amount)
    self.balance = balance.to_i - amount.to_i
    self.hold_balance = hold_balance.to_i + amount.to_i
    save!
  end

  def token_symbol
    self.token.symbol
  end

  def release(amount)
    self.balance = balance.to_i + amount.to_i
    self.hold_balance = hold_balance.to_i - amount.to_i
    save!
  end

  def spend(amount)
    self.hold_balance = hold_balance.to_i - amount.to_i
    save!
  end

  private

  def remove_checksum
    self.account_address = self.account_address.without_checksum
    self.token_address = self.token_address.without_checksum
  end
end
