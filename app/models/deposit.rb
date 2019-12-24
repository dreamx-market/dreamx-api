class Deposit < ApplicationRecord
  belongs_to :account, class_name: 'Account', foreign_key: 'account_address', primary_key: 'address'
  belongs_to :token, class_name: 'Token', foreign_key: 'token_address', primary_key: 'address'

  validates :transaction_hash, uniqueness: true
  validates :transaction_hash, presence: true
  
  validates :amount, numericality: { greater_than: 0 }

  before_create :remove_checksum, :credit_balance_with_lock
  after_commit { AccountTransfersRelayJob.perform_later(self) }

  def balance
    self.account.balance(self.token_address)
  end

  # to distinguish this model from withdraws when being displayed a mixed collection of transfers
  def type
    'deposit'
  end

  def account_address
    self.account.address
  end

  private

  def credit_balance_with_lock
    balance = self.balance
    balance.with_lock do
      balance.credit(self.amount)
    end
  end

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
        :status => 'confirmed'
      }
      begin
        self.create!(new_deposit)
      rescue => err
        logger.debug "Failed to create deposit, received the following error: #{err}"
      end
    end
  end

  def remove_checksum
    self.account_address = self.account_address.without_checksum
    self.token_address = self.token_address.without_checksum
  end
end
