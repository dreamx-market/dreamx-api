class Ejection < ApplicationRecord
  belongs_to :account
  has_one :tx, class_name: 'Transaction', as: :transactable

  validates :account_address, uniqueness: true

  before_validation :build_transaction, on: :create

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
