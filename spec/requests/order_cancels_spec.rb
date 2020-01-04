require 'rails_helper'

RSpec.describe "OrderCancels", type: :request do
  describe "POST /order_cancels" do
    it "cancels an order" do
      order = create(:order)
      order_cancel = build(:order_cancel, order: order)

      expect {
      expect {
      expect {
        post order_cancels_url, params: [order_cancel], as: :json
        order.reload
        expect(response).to be_successful
        expect(order.status).to eq('closed')
      }.to increase { order.balance.balance }.by(order.remaining_give_amount)
      }.to decrease { order.balance.hold_balance }.by(order.remaining_give_amount)
      }.to increase { OrderCancel.count }.by(1)
    end

    it "cancels multiple orders" do
      order_cancels = build_list(:order_cancel, 3)
      
      expect {
        post order_cancels_url, params: order_cancels, as: :json
        expect(response).to be_successful
      }.to increase { OrderCancel.count }.by(3)
    end

    it "rollbacks the whole batch if there is an invalid order cancel" do
      order_cancels = build_list(:order_cancel, 3)
      order_cancels.last.signature = 'INVALID'

      expect {
        post order_cancels_url, params: order_cancels, as: :json
        expect(response).to_not be_successful
      }.to increase { OrderCancel.count }.by(0)
    end
  end
end
