require 'test_helper'

class TransfersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @withdraw = withdraws(:one)
  end

  # test "should get index" do
  #   get transfers_url, as: :json
  #   assert_response :success
  # end

  # test "should create transfer" do
  #   assert_difference('Transfer.count') do
  #     post transfers_url, params: { transfer: {  } }, as: :json
  #   end

  #   assert_response 201
  # end

  test "should show transfer" do
    get transfer_url(@withdraw.account_address), as: :json
    assert_response :success
  end

  # test "should update transfer" do
  #   patch transfer_url(@transfer), params: { transfer: {  } }, as: :json
  #   assert_response 200
  # end

  # test "should destroy transfer" do
  #   assert_difference('Transfer.count', -1) do
  #     delete transfer_url(@transfer), as: :json
  #   end

  #   assert_response 204
  # end
end
