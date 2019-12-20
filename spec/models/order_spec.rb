require 'rails_helper'

RSpec.describe Order, type: :model do
  it "is a buy order with insufficient volume" do
    order = build(:order, :buy)
    expect(order.has_sufficient_remaining_volume?).to be(true)
    order.filled = '0.955'.to_wei
    expect(order.has_sufficient_remaining_volume?).to be(false)
  end

  it "is a sell order with insufficient volume" do
    order = build(:order, :sell)
    expect(order.has_sufficient_remaining_volume?).to be(true)
    order.filled = '0.88'.to_wei
    expect(order.has_sufficient_remaining_volume?).to be(false)
  end
end
