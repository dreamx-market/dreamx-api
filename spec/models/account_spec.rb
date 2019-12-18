require 'rails_helper'

RSpec.describe Account, type: :model do
  it "successfully ejects", :onchain do
    account = create(:account)
    allow(account).to receive(:close_all_open_orders)

    account.eject
    expect(account.ejected).to eq(true)
    expect(account).to have_received(:close_all_open_orders)
    expect(Ejection.count).to eq(1)
    expect(Transaction.count).to eq(1)

    ejection = Ejection.last
    exchange = Contract::Exchange.singleton.instance
    BroadcastTransactionJob.perform_now(ejection.tx)
    expect(exchange.call.account_manual_withdraws(account.address)).to eq(true)
  end
end
