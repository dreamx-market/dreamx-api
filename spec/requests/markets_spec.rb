require 'rails_helper'

RSpec.describe "Markets", type: :request do
  before(:each) do
    @market = markets(:one)
  end

  it "GET /markets" do
    get markets_url, as: :json
    expect(response).to be_successful
  end
end
