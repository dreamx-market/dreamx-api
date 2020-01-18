class Deposit < ApplicationRecord
  belongs_to :account
  belongs_to :token
  belongs_to :balance

  validates :transaction_hash, uniqueness: true
  validates :transaction_hash, :account_address, :token_address, :amount, :block_number, presence: true
  validates :amount, numericality: { greater_than: 0 }

  before_validation :initialize_attributes, :lock_attributes, on: :create
  before_validation :remove_checksum
  before_create :credit_balance
  after_commit { AccountTransfersRelayJob.perform_later(self) }

  # static attributes used for rendering _transfer.json.jbuilder
  def type
    'deposit'
  end

  def status
    'confirmed'
  end

  def credit_balance
    self.balance.credit(self.amount)
  end

  def initialize_attributes
    self.account = Account.find_by(address: self.account_address)
    self.token = Token.find_by(address: self.token_address)

    if self.account && self.token
      self.balance = self.account.balance(self.token.address)
    end
  end

  private

  def lock_attributes
    if self.balance
      self.balance.lock!
    end
  end

  def self.missing(from, to=from)
    exchange = Contract::Exchange.singleton
    deposits = exchange.deposits(from, to)

    missing = []
    deposits.each do |deposit|
      offchain_deposit = self.find_by(transaction_hash: deposit[:transaction_hash])
      missing << deposit if !offchain_deposit
    end

    return missing
  end

  def self.aggregate(from, to=from)
    exchange = Contract::Exchange.singleton
    deposits = exchange.deposits(from, to)
    deposits.each do |deposit|
      deposit[:account] = deposit[:account].without_checksum
      deposit[:token] = deposit[:token].without_checksum
      balance = Balance.find_or_create_by({ account_address: deposit[:account], token_address: deposit[:token] })
      new_deposit = {
        account_address: deposit[:account],
        token_address: deposit[:token],
        amount: deposit[:amount],
        transaction_hash: deposit[:transaction_hash],
        block_number: deposit[:block_number],
      }
      self.create!(new_deposit)
    end
  end

  def remove_checksum
    if self.account_address.is_a_valid_address? && self.token_address.is_a_valid_address?
      self.account_address = self.account_address.without_checksum
      self.token_address = self.token_address.without_checksum
    end
  end
end
