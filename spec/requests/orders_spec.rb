require 'rails_helper'

RSpec.describe "Orders", type: :request do
  describe "GET /orders" do
    it "returns all orders" do
      create(:order)
      get orders_url, as: :json
      expect(response).to be_successful
      expect(json['total']).to eq(1)
    end
  end

  describe "GET /orders/:order_hash" do
    it "shows an order" do
      order = create(:order)
      get order_url(order.order_hash), as: :json
      expect(response).to be_successful
    end
  end

  describe "POST /orders" do
    it "creates an order" do
      order = build(:order)

      expect {
      expect {
      expect {
        post orders_url, params: order, as: :json
        expect(response).to be_successful
      }.to have_decreased { order.balance.balance }.by(order.give_amount)
      }.to have_increased { order.balance.hold_balance }.by(order.give_amount)
      }.to have_increased { Order.count }.by(1)
    end
  end
end
