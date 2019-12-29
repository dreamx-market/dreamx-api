require 'rails_helper'

RSpec.describe "OrderBooks", type: :request do
  before(:each) do
    @market_symbol = "ONE_ETH"
  end

  describe 'GET /order_books/:market_symbol' do
    it "returns an order book" do
      get order_book_url(@market_symbol), as: :json
      expect(response).to be_successful
    end

    it 'returns 404 response' do
      get order_book_url({ market_symbol: 'invalid' }), as: :json
      expect(response).to have_http_status(:not_found)
    end
  end
end
