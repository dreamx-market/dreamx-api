require 'test_helper'

class CurrenciesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
  	get currencies_url, as: :json
    assert_response :success
    assert_equal json.length, 3
    assert_equal json[0]
    assert_equal json[1]
    assert_equal json[2]
  end
end
