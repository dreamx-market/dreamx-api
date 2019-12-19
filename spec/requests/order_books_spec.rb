require 'rails_helper'

RSpec.describe "OrderBooks", type: :request do
  before(:each) do
    @market_symbol = "ONE_ETH"
  end

  it "GET /order_books/:market_symbol" do
    get order_book_url(@market_symbol), as: :json
    expect(response).to be_successful
  end
end
