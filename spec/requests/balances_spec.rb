require 'rails_helper'

RSpec.describe "Balances", type: :request do
  before(:each) do
    @balance = balances(:one_eth)
  end

  it "GET /balances" do
    get balance_url(@balance.account_address), as: :json
    expect(response).to have_http_status(:success)
    expect(json['records'].length).to eq(3)
  end
end
