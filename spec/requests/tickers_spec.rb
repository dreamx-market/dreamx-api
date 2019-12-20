require 'rails_helper'

RSpec.describe "Tickers", type: :request do
  it "GET /tickers" do
    get tickers_url, as: :json
    expect(response).to be_successful
    expect(json[:total]).to eq(1)
  end

  it "GET /tickers/:market_symbol" do
    market_symbol = 'ONE_ETH'
    get ticker_url(market_symbol), as: :json
    expect(response).to be_successful
  end
end
