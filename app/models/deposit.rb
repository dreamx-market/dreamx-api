class Deposit < ApplicationRecord
  include FraudProtectable
  
  belongs_to :account, class_name: 'Account', foreign_key: 'account_address', primary_key: 'address'
  belongs_to :token, class_name: 'Token', foreign_key: 'token_address', primary_key: 'address'

  validates :amount, numericality: { greater_than: 0 }
  validate :balances_must_be_authentic, on: :create

  before_create :credit_balance

  private

  # def transaction_hash_must_be_unique
    
  # end

  def credit_balance
    if (!self.account)
      return
    end

    self.account.balance(self.token_address).credit(self.amount)
  end

  def balances_must_be_authentic
    if (!self.account)
      return
    end

    validate_balances_integrity(self.account.balance(self.token_address))
  end

  def self.aggregate(block_number)
    # confirmed_block_number = block_number - ENV['TRANSACTION_CONFIRMATIONS'].to_i
    @exchange ||= Contract::Exchange.new
    deposits = @exchange.deposits(block_number)
    deposits.each do |deposit|
      Account.initialize_if_not_exist(deposit['account'], deposit['token'])
      new_deposit = {
        :account_address => deposit['account'],
        :token_address => deposit['token'],
        :amount => deposit['amount'],
        :status => 'confirmed',
        :transaction_hash => deposit['transaction_hash'],
        :block_hash => deposit['block_hash'],
        :block_number => deposit['block_number']
      }
      self.create!(new_deposit)
    end
  end
end
