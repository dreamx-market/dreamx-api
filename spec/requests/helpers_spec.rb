require 'rails_helper'

RSpec.describe "Helpers", type: :request do
  it "GET /return_contract_address" do
    get return_contract_address_url
    expect(response).to be_successful
  end

  it "GET /fees" do
    get fees_url
    expect(response).to be_successful
  end
end
