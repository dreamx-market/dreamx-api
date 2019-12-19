require 'rails_helper'

RSpec.describe "ChartData", type: :request do
  before(:each) do
    @market_symbol = 'ONE_ETH'
  end

  it "GET /chart_data" do
    get chart_datum_url(@market_symbol), as: :json
    expect(response).to be_successful
  end
end
