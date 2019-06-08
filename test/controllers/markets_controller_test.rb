require 'test_helper'

class MarketsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @market = markets(:one)
  end

  test "should get index" do
    get markets_url, as: :json
    assert_response :success
  end

  # test "should create market" do
  # 	@market.destroy

  #   assert_difference('Market.count') do
  #     post markets_url, params: { market: { base_token_address: @market.base_token_address, quote_token_address: @market.quote_token_address } }, as: :json
  #   end

  #   assert_response 201
  # end

  # test "should show market" do
  #   get market_url(@market), as: :json
  #   assert_response :success
  # end

  # test "should update market" do
  #   patch market_url(@market), params: { market: { base_token_address: @market.base_token_address, quote_token_address: @market.quote_token_address } }, as: :json
  #   assert_response 200
  # end

  # test "should destroy market" do
  #   assert_difference('Market.count', -1) do
  #     delete market_url(@market), as: :json
  #   end

  #   assert_response 204
  # end
end
