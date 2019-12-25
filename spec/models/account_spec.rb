require 'rails_helper'

RSpec.describe Account, type: :model do
  let (:account) { build(:account) }

  it "ejects with lock", :onchain do
    allow(account).to receive(:close_all_open_orders)
    allow(account).to receive(:with_lock).and_call_original

    account.eject

    expect(account.ejected).to eq(true)
    expect(account).to have_received(:close_all_open_orders)
    expect(account).to have_received(:with_lock).once
    expect(Ejection.count).to eq(1)
    expect(Transaction.count).to eq(1)

    ejection = Ejection.last
    exchange = Contract::Exchange.singleton
    BroadcastTransactionJob.perform_now(ejection.tx)
    expect(exchange.account_manual_withdraws(account.address)).to eq(true)
  end
end
