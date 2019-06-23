require 'test_helper'

class HelpersControllerTest < ActionDispatch::IntegrationTest
  test "GET /return_contract_address" do
    get return_contract_address_url
    assert_response :success
    assert_equal json["address"], ENV['CONTRACT_ADDRESS'].without_checksum
  end

  test "GET /fees" do
    get fees_url
    assert_response :success
  end
end
