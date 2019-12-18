require 'rails_helper'

RSpec.describe AccountBalancesChannel, type: :channel do
  it "broadcasts a message when a new deposit is created", :perform_enqueued do
    deposit = build(:deposit)

    expect {
      deposit.save
    }.to have_broadcasted_to("account_balances:#{deposit.account_address}")
  end

  it "broadcasts a message when a new withdrawal is created", :perform_enqueued, :with_funded_accounts do
    withdraw = build(:withdraw)

    expect {
      withdraw.save
    }.to have_broadcasted_to("account_balances:#{withdraw.account_address}")
  end
end
