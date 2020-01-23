require 'rails_helper'

RSpec.describe Ejection, type: :model do
  it 'must be unique on a per-account basis' do
    ejection1 = create(:ejection)
    ejection2 = build(:ejection, account: ejection1.account)
    expect(ejection2.valid?).to eq(false)
    expect(ejection2.errors.messages[:account_address]).to include('has already been taken')
  end

  it 'cancels account orders upon creation' do
    orders = create_list(:order, 3)
    account = orders.first.account
    create(:ejection, account: account)
    expect(account.open_orders.count).to eq(0)
  end

  it "aggregates new ejections" do
    create(:account, address: "0x8e434a440b666646bdf8261239cdcd1f01189259") # account must exist for the ejection to be aggregated
    allow(Etherscan).to receive(:send_request).and_return(etherscan_ejections)

    expect {
      from = 7179750
      to = 7179750
      Ejection.aggregate(from, to)
    }.to increase { Ejection.count }.by(1)
  end
end
