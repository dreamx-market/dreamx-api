require 'rails_helper'

RSpec.describe Ejection, type: :model do
  it 'must be unique on a per-account basis' do
    ejection1 = create(:ejection)
    ejection2 = build(:ejection, account: ejection1.account)
    expect(ejection2.valid?).to eq(false)
    expect(ejection2.errors.messages[:account_address]).to include('has already been taken')
  end

  it 'cancels account orders upon creation', :focus do
    orders = create_list(:order, 3)
    account = orders.first.account
    create(:ejection, account: account)
    expect(account.open_orders.count).to eq(0)
  end
end
