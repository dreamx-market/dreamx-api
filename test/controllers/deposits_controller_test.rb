require 'test_helper'

class DepositsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @deposit = deposits(:one)
  end

  test "should get index" do
    get deposits_url, as: :json
    assert_response :success
  end

  test "should create deposit" do
    assert_difference('Deposit.count') do
      post deposits_url, params: { deposit: { account_address: @deposit.account_address, amount: @deposit.amount, token_address: @deposit.token_address } }, as: :json
    end

    assert_response 201
  end

  test "should show deposit" do
    get deposit_url(@deposit), as: :json
    assert_response :success
  end

  test "should update deposit" do
    patch deposit_url(@deposit), params: { deposit: { account_address: @deposit.account_address, amount: @deposit.amount, token_address: @deposit.token_address } }, as: :json
    assert_response 200
  end

  test "should destroy deposit" do
    assert_difference('Deposit.count', -1) do
      delete deposit_url(@deposit), as: :json
    end

    assert_response 204
  end
end
