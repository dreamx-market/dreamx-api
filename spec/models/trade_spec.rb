require 'rails_helper'

RSpec.describe Trade, type: :model do
  let (:trade) { build(:trade) }

  it 'must be created by an account with a sufficient balance', :focus do
    trade.amount = trade.balance.balance.to_i * 2
    expect(trade.valid?).to eq(false)
    pp trade.errors.messages
  end
end
