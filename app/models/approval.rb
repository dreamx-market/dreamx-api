class Approval < ApplicationRecord
  belongs_to :account
  belongs_to :balance
  belongs_to :token
  has_one :tx, class_name: 'Transaction', as: :transactable

  validates :transaction_hash, uniqueness: true
  validates :amount, numericality: { greater_than: 0 }

  before_validation :remove_checksum, :build_transaction

  class << self
    def aggregate(from, to=from)
      Token.all.each do |token|
        approvals = token.approvals(from, to)
        approvals.each do |approval|
          balance = Balance.find_or_create_by({ account_address: approval[:owner].without_checksum, token_address: token.address })
          account = balance.account
          new_approval = self.new({
            account_id: account.id,
            account_address: account.address,
            balance_id: balance.id,
            token_id: token.id,
            token_address: token.address,
            transaction_hash: approval[:transaction_hash],
            block_number: approval[:block_number],
            amount: approval[:value]
          })
          new_approval.save!
        end
      end
    end

    def missing
      result = []
      Token.all.each do |token|
        approvals = token.approvals(from, to)
        approvals.each do |approval|
          offchain_approval = self.find_by(transaction_hash: approval[:transaction_hash])
          result << approval if !offchain_approval
        end
      end
      return result
    end
  end

  def payload
    exchange = Contract::Exchange.singleton
    fun = exchange.functions('depositToken')
    args = [self.token_address, self.account_address, self.amount.to_i]
    exchange.call_payload(fun, args)
  end

  private

  def remove_checksum
    if self.account_address.is_a_valid_address? && self.token_address.is_a_valid_address?
      self.account_address = self.account_address.without_checksum
      self.token_address = self.token_address.without_checksum
    end
  end

  def build_transaction
    self.tx ||= Transaction.new({ status: 'pending' })
  end
end
