class Balance < ApplicationRecord
  has_many :refunds, dependent: :destroy
  has_many :deposits, dependent: :destroy
  has_many :withdraws, dependent: :destroy
  has_many :orders, foreign_key: 'give_balance_id'
  has_many :open_orders, -> { open }, class_name: 'Order', foreign_key: 'give_balance_id'
  has_many :closed_orders, -> { closed }, class_name: 'Order', foreign_key: 'give_balance_id'
  has_many :closed_and_partially_filled_sell_orders, -> { closed_and_partially_filled }, class_name: 'Order', foreign_key: 'give_balance_id'
  has_many :closed_and_partially_filled_buy_orders, -> { closed_and_partially_filled }, class_name: 'Order', foreign_key: 'take_balance_id'
  has_many :buy_trades, class_name: 'Trade', foreign_key: 'give_balance_id'
  has_many :sell_trades, class_name: 'Trade', foreign_key: 'take_balance_id'
  alias_attribute :trades, :sell_trades
  belongs_to :token
  belongs_to :account

	validates_uniqueness_of :account_address, scope: [:token_address]
  validates :balance, :hold_balance, numericality: { :greater_than_or_equal_to => 0 }

  before_validation :initialize_attributes, on: :create
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

    def has_unauthentic_onchain_balances?
      self.all.each do |b|
        if !b.onchain_authentic?
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

    def unauthentic_onchain_balances
      result = []

      self.all.each do |b|
        if !b.onchain_authentic?
          result << b
        end
      end

      return result
    end

    def sync_unauthentic_balances
      self.unauthentic_onchain_balances do |b|
        b.sync_with_onchain
      end
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

    def sync_fee_balances
      Token.all.each do |token|
        balance = Balance.fee(token.symbol)
        balance.update(balance: balance.onchain_balance)
      end
    end
  end

  def sync_with_onchain
    delta = self.onchain_delta

    if delta > 0
      deposit = self.deposits.last
      deposit.amount += delta
      deposit.save!
      self.balance += delta
      self.save!
    else
      withdraw = self.withdraws.last
      withdraw.amount -= delta
      withdraw.save!(validate: false)
      self.balance += delta
      self.save!
    end
  end

  def initialize_attributes
    self.token = Token.find_by(address: self.token_address)
    self.account = Account.find_or_create_by(address: self.account_address)
  end

  def onchain_balance
    exchange = Contract::Exchange.singleton
    return exchange.balances(self.token_address, self.account_address)
  end

  def onchain_delta
    self.onchain_balance.to_i - self.total_balance.to_i
  end

  def real_delta
    self.real_balance.to_i - self.balance.to_i
  end

  def real_hold_delta
    self.reload.real_hold_balance.to_i - self.hold_balance.to_i
  end

  def mark_fraud
    self.with_lock do
      self.fraud = true
      self.save!
      AppLogger.log("marked balance ##{self.id} as fraud")
    end
  end

  def authentic?
    fee_address = ENV['FEE_COLLECTOR_ADDRESS'].without_checksum
    if (fee_address == self.account_address)
      return true
    end

    return self.real_delta == 0 && self.real_hold_delta == 0
  end

  def onchain_authentic?
    fee_address = ENV['FEE_COLLECTOR_ADDRESS'].without_checksum
    if (fee_address == self.account_address || self.account.ejected)
      return true
    end

    return self.onchain_delta == 0
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

  def total_traded
    total = 0
    self.closed_and_partially_filled_sell_orders.each do |o|
      total -= o.filled.to_i
    end
    # DO NOT use order.filled to calculate maker_receiving_amount
    # maker_receiving_amount must be calculated by adding up the individual trades
    # to accurately take into account the truncation that occurs after each trade
    self.closed_and_partially_filled_buy_orders.includes(:trades).each do |o|
      o.trades.each do |t|
        total += t.maker_receiving_amount_after_fee.to_i
      end
    end
    self.buy_trades.each do |t|
      total += t.taker_receiving_amount_after_fee.to_i
    end
    self.sell_trades.each do |t|
      total -= t.take_amount.to_i
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

  def credit(amount)
    self.balance += amount.to_i
    self.save!
  end

  def debit(amount)
    self.balance -= amount.to_i
    self.save!
  end

  def hold(amount)
    self.balance -= amount.to_i
    self.hold_balance += amount.to_i
    self.save!
  end

  def release(amount)
    self.balance += amount.to_i
    self.hold_balance -= amount.to_i
    self.save!
  end

  def spend(amount)
    self.hold_balance -= amount.to_i
    self.save!
  end

  private

  def remove_checksum
    self.account_address = self.account_address.without_checksum
    self.token_address = self.token_address.without_checksum
  end
end
