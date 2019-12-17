require 'rails_helper'

RSpec.describe Account, type: :model do
  it "successfully ejects" do
    expect {
    expect {
      account = create(:account)
      account.eject
      expect(account.ejected).to eq(true)
    }.to change { Ejection.count }
    }.to change { Transaction.count }
  end
end
