require 'test_helper'

class CurrenciesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
  	get currencies_url, as: :json
    assert_response :success
    assert_equal json.length, 3
    assert_equal json[0], { "name" => currencies(:ETH).name, "symbol" => currencies(:ETH).symbol, "decimals" => currencies(:ETH).decimals, "address" => currencies(:ETH).address }
    assert_equal json[1], { "name" => currencies(:REP).name, "symbol" => currencies(:REP).symbol, "decimals" => currencies(:REP).decimals, "address" => currencies(:REP).address }
    assert_equal json[2], { "name" => currencies(:TRX).name, "symbol" => currencies(:TRX).symbol, "decimals" => currencies(:TRX).decimals, "address" => currencies(:TRX).address }
  end
end
