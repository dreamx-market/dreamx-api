require 'test_helper'

class CurrenciesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
  	res = get currencies_url, as: :json
    assert_response :success
  end
end
