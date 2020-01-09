require 'rails_helper'

RSpec.describe AccountTransfersChannel, type: :channel, perform_enqueued: true do
  it "broadcast message when deposit is created" do
    deposit = build(:deposit)

    expect {
      deposit.save
    }.to have_broadcasted_to("account_transfers:#{deposit.account_address}")
  end

  it "broadcast message when withdrawal is created or updated", :onchain do
    withdraw = build(:withdraw)

    expect {
      withdraw.save
    }.to have_broadcasted_to("account_transfers:#{withdraw.account_address}").twice
  end
end
