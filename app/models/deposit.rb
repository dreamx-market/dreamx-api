class Deposit < ApplicationRecord
  belongs_to :account
  belongs_to :token
  belongs_to :balance

  validates :transaction_hash, uniqueness: true
  validates :transaction_hash, :account_address, :token_address, :amount, :block_hash, :block_number, presence: true
  validates :amount, numericality: { greater_than: 0 }

  before_validation :initialize_attributes, on: :create
  before_validation :remove_checksum
  before_create :credit_balance_with_lock
  after_commit { AccountTransfersRelayJob.perform_later(self) }

  # to distinguish this model from withdraws when being displayed a mixed collection of transfers
  def type
    'deposit'
  end

  def credit_balance_with_lock
    balance = self.balance
    balance.with_lock do
      balance.credit(self.amount)
    end
  end

  def initialize_attributes
    self.account = Account.find_by(address: self.account_address)
    self.token = Token.find_by(address: self.token_address)

    if self.account && self.token
      self.balance = self.account.balance(self.token.address)
    end
  end

  private

  def self.aggregate(block_number)
    exchange = Contract::Exchange.singleton
    deposits = exchange.deposits(block_number)
    deposits.each do |deposit|
      deposit['account'], deposit['token'] = deposit['account'].without_checksum, deposit['token'].without_checksum
      Balance.find_or_create_by({ account_address: deposit['account'], token_address: deposit['token'] })
      new_deposit = {
        :account_address => deposit['account'],
        :token_address => deposit['token'],
        :amount => deposit['amount'],
        :transaction_hash => deposit['transaction_hash'],
        :block_hash => deposit['block_hash'],
        :block_number => deposit['block_number'],
      }
      begin
        self.create!(new_deposit)
      rescue => err
        logger.debug "Failed to create deposit, received the following error: #{err}"
      end
    end
  end

  def remove_checksum
    if self.account_address.is_a_valid_address? && self.token_address.is_a_valid_address?
      self.account_address = self.account_address.without_checksum
      self.token_address = self.token_address.without_checksum
    end
  end
end
