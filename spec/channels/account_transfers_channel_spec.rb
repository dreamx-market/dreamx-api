require 'rails_helper'

RSpec.describe AccountTransfersChannel, type: :channel, perform_enqueued: true do
  it "broadcasts a message when new deposit is created" do
    deposit = build(:deposit)

    expect {
      deposit.save
    }.to have_broadcasted_to("account_transfers:#{deposit.account_address}")
  end

  it "broadcasts a message when a new withdrawal is created", :onchain do
    withdraw = build(:withdraw)

    expect {
      withdraw.save
    }.to have_broadcasted_to("account_transfers:#{withdraw.account_address}")
  end
end
