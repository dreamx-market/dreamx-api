require 'rails_helper'

RSpec.describe "Withdraws", type: :request do
  describe "POST /withdraws" do
    it "creates a withdrawal", :onchain, :perform_enqueued do
      withdraw = build(:withdraw)
      balance = withdraw.balance

      expect {
      expect {
      expect {
        post withdraws_url, params: withdraw, as: :json
        expect(response).to have_http_status(201)
        expect(balance.reload.onchain_delta).to eq(0)
      }.to increase { Withdraw.count }.by(1)
      }.to increase { Transaction.count }.by(1)
      }.to decrease { balance.reload.balance }.by(withdraw.amount)
    end
  end
end
