require 'rails_helper'

RSpec.describe "Tokens", type: :request do
  it "GET /tokens" do
    get tokens_url, as: :json
    expect(response).to be_successful
    expect(json['records'].count).to eq(3)
  end
end
