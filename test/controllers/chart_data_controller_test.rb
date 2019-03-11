require 'test_helper'

class ChartDataControllerTest < ActionDispatch::IntegrationTest
  setup do
    @chart_datum = chart_data(:one)
  end

  # test "should get index" do
  #   get chart_data_url, as: :json
  #   assert_response :success
  # end

  # test "should create chart_datum" do
  #   assert_difference('ChartDatum.count') do
  #     post chart_data_url, params: { chart_datum: { close: @chart_datum.close, high: @chart_datum.high, low: @chart_datum.low, open: @chart_datum.open, period: @chart_datum.period, quote_volume: @chart_datum.quote_volume, volume: @chart_datum.volume } }, as: :json
  #   end

  #   assert_response 201
  # end

  test "should show chart_datum" do
    get chart_datum_url(@chart_datum.market_symbol), as: :json
    pp json
    assert_response :success
  end

  # test "should update chart_datum" do
  #   patch chart_datum_url(@chart_datum), params: { chart_datum: { close: @chart_datum.close, high: @chart_datum.high, low: @chart_datum.low, open: @chart_datum.open, period: @chart_datum.period, quote_volume: @chart_datum.quote_volume, volume: @chart_datum.volume } }, as: :json
  #   assert_response 200
  # end

  # test "should destroy chart_datum" do
  #   assert_difference('ChartDatum.count', -1) do
  #     delete chart_datum_url(@chart_datum), as: :json
  #   end

  #   assert_response 204
  # end
end
