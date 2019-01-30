require 'test_helper'

class TokensControllerTest < ActionDispatch::IntegrationTest
  setup do
    @token = tokens(:one)
  end

  test "should get index" do
    get tokens_url, as: :json
    assert_response :success
  end

  test "should create token" do
    assert_difference('Token.count') do
      post tokens_url, params: { token: { address: @token.address, decimals: @token.decimals, name: @token.name, symbol: @token.symbol } }, as: :json
    end

    assert_response 201
  end

  test "should show token" do
    get token_url(@token), as: :json
    assert_response :success
  end

  test "should update token" do
    patch token_url(@token), params: { token: { address: @token.address, decimals: @token.decimals, name: @token.name, symbol: @token.symbol } }, as: :json
    assert_response 200
  end

  test "should destroy token" do
    assert_difference('Token.count', -1) do
      delete token_url(@token), as: :json
    end

    assert_response 204
  end
end
