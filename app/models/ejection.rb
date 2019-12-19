class Ejection < ApplicationRecord
  belongs_to :account, class_name: 'Account', foreign_key: 'account_address', primary_key: 'address'
  has_one :tx, class_name: 'Transaction', as: :transactable

  before_create :build_transaction

  def payload
    exchange = Contract::Exchange.singleton
    fun = exchange.instance.parent.functions.select { |fun| fun.name == 'setAccountManualWithdraws'}.first
    args = [self.account.address, true]
    exchange.instance.parent.call_payload(fun, args)
  end

  private

  def build_transaction
    self.tx = Transaction.new({ status: 'pending' })
  end
end
