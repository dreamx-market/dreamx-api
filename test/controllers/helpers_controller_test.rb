require 'test_helper'

class HelpersControllerTest < ActionDispatch::IntegrationTest
  test "should get return_contract_address" do
    get return_contract_address_url
    assert_response :success
    assert_equal json["address"], ENV['CONTRACT_ADDRESS']
  end
end
