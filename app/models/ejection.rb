class Ejection < ApplicationRecord
  belongs_to :account, class_name: 'Account', foreign_key: 'account_address', primary_key: 'address'
  has_one :tx, class_name: 'Transaction', as: :transactable

  validates :account_address, uniqueness: true

  after_initialize :build_transaction, if: :new_record?

  def payload
    exchange = Contract::Exchange.singleton
    fun = exchange.functions('setAccountManualWithdraws')
    args = [self.account.address, true]
    exchange.call_payload(fun, args)
  end

  private

  def build_transaction
    self.tx = Transaction.new({ status: 'pending' })
  end
end
