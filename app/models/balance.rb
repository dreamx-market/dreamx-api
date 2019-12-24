class Balance < ApplicationRecord
  has_many :refunds, dependent: :destroy
  belongs_to :token, class_name: 'Token', foreign_key: 'token_address', primary_key: 'address'  
  belongs_to :account, class_name: 'Account', foreign_key: 'account_address', primary_key: 'address'

	validates_uniqueness_of :account_address, scope: [:token_address]
  validates :balance, :hold_balance, numericality: { :greater_than_or_equal_to => 0 }

  after_initialize :initialize_account_if_not_exist
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

    def unauthentic_balances
      result = []

      self.all.each do |b|
        if !b.authentic?
          result << b
        end
      end

      return result
    end

    def fee(token_address_or_symbol)
      if (!token_address_or_symbol.is_a_valid_address?)
        token = Token.find_by({ symbol: token_address_or_symbol.upcase })
        token_address = token.address
      else
        token_address = token_address_or_symbol
      end

      fee_address = ENV['FEE_COLLECTOR_ADDRESS'].without_checksum
      self.find_or_create_by({ :account_address => fee_address, :token_address => token_address })
    end
  end

  def initialize_account_if_not_exist
    if !self.account
      self.account = Account.new({ address: self.account_address })
    end
  end

  def onchain_balance
    exchange = Contract::Exchange.singleton
    onchain_balance = exchange.balances(self.token_address, self.account_address)
    return onchain_balance.to_s
  end

  def onchain_delta
    self.total_balance.to_i - self.onchain_balance.to_i
  end

  def mark_fraud
    self.with_lock do
      self.fraud = true
      self.save!
      # debugging only, remove logging before going live
      AppLogger.log("marked balance ##{self.id} as fraud")
    end
  end

  def authentic?
    fee_address = ENV['FEE_COLLECTOR_ADDRESS'].without_checksum
    if (fee_address == self.account_address)
      return true
    end

    return (balance_authentic? and hold_balance_authentic?)
  end

  def balance_authentic?
    return self.reload.real_balance.to_i == self.balance.to_i
  end

  def real_total_balance
    self.real_balance.to_i + self.real_hold_balance.to_i
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
    return self.reload.real_hold_balance.to_i == self.hold_balance.to_i
  end

  def open_orders
    Order.where({ :account_address => account_address, :give_token_address => token_address }).where.not({ status: 'closed' })
  end

  def closed_orders
    Order.where({ :account_address => account_address, :give_token_address => token_address }).where({ status: 'closed' })
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

  def trades
    # orders included for both sell and buy trades
    Trade.joins(:order).where( :trades => { :account_address => account_address }, :orders => { :take_token_address => token_address } ).includes(:order).or(Trade.joins(:order).where( :trades => { :account_address => account_address }, :orders => { :give_token_address => token_address } ).includes(:order))
  end

  def sell_trades
    Trade.joins(:order).where( :trades => { :account_address => account_address }, :orders => { :take_token_address => token_address } ).includes(:order)
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
      total += order.filled_take_minus_fee.to_i
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

  def token_symbol
    self.token.symbol
  end

  # balance altering operations

  def credit(amount)
    self.balance = self.balance.to_i + amount.to_i
    self.save!
  end

  def debit(amount)
    self.balance = self.balance.to_i - amount.to_i
    self.save!
  end

  def hold(amount)
    self.balance = balance.to_i - amount.to_i
    self.hold_balance = hold_balance.to_i + amount.to_i
    self.save!
  end

  def release(amount)
    self.balance = balance.to_i + amount.to_i
    self.hold_balance = hold_balance.to_i - amount.to_i
    self.save!
  end

  def spend(amount)
    self.hold_balance = hold_balance.to_i - amount.to_i
    self.save!
  end

  private

  def remove_checksum
    self.account_address = self.account_address.without_checksum
    self.token_address = self.token_address.without_checksum
  end
end
