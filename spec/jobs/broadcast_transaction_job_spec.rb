require 'rails_helper'

RSpec.describe BroadcastTransactionJob, type: :job do
  it "broadcasts and updates a transaction", :onchain do
    trade = create(:trade)
    transaction = trade.tx
    expect(transaction).to have_attributes({ status: 'pending' })
    BroadcastTransactionJob.perform_now(transaction)
    expect(transaction.reload).to have_attributes({ status: 'unconfirmed' })
  end
end
