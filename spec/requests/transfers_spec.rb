require 'rails_helper'

RSpec.describe "Transfers", type: :request do
  describe "GET /transfers" do
    it "returns a transfer" do
      withdraw = create(:withdraw)
      get transfer_url(withdraw.account_address), as: :json
      expect(response).to have_http_status(200)
    end
  end
end
