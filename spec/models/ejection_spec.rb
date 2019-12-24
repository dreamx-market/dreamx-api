require 'rails_helper'

RSpec.describe Ejection, type: :model do
  it 'must be unique on a per-account basis' do
    ejection1 = create(:ejection)
    ejection2 = build(:ejection, account: ejection1.account)
    expect(ejection2.valid?).to eq(false)
    expect(ejection2.errors.messages[:account_address]).to include('has already been taken')
  end
end
