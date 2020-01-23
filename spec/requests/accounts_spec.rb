require 'rails_helper'

RSpec.describe "Accounts", type: :request do
  it "GET /accounts/:address" do
    account = accounts(:one)
    get account_url(account.address)
    expect(response).to be_successful
  end
end
