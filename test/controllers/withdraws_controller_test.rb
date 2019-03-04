require 'test_helper'

class WithdrawsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @old_contract_address = ENV['CONTRACT_ADDRESS']
    ENV['CONTRACT_ADDRESS'] = "0x4ef6474f40bf5c9dbc013efaac07c4d0cb17219a"

    @withdraw = withdraws(:one)
    @balance = balances(:one)
    @balance.release(@withdraw.amount)
  end

  teardown do
    ENV['CONTRACT_ADDRESS'] = @old_contract_address
  end

  # test "should get index" do
  #   get withdraws_url, as: :json
  #   assert_response :success
  # end

  # test "should create withdraw and debit balance" do
  #   @withdraw.destroy

  #   before_withdraw_balances = [
  #     { :account_address => @withdraw.account_address, :token_address => @withdraw.token_address, :balance => 100000000000000000000, :hold_balance => 0 }
  #   ]
  #   after_withdraw_balances = [
  #     { :account_address => @withdraw.account_address, :token_address => @withdraw.token_address, :balance => 0, :hold_balance => 0 }
  #   ]
  #   after_withdraw_withdraws = [
  #     { :withdraw_hash => @withdraw.withdraw_hash, :fee => "1".to_wei }
  #   ]

  #   assert_model(Balance, before_withdraw_balances)

  #   assert_difference('Withdraw.count') do
  #     post withdraws_url, params: { withdraw: { account_address: @withdraw.account_address, amount: @withdraw.amount, nonce: @withdraw.nonce, signature: @withdraw.signature, token_address: @withdraw.token_address, withdraw_hash: @withdraw.withdraw_hash } }, as: :json
  #   end

  #   assert_model(Balance, after_withdraw_balances)
  #   assert_model(Withdraw, after_withdraw_withdraws)

  #   assert_response 201
  # end

  # test "should show withdraw" do
  #   get withdraw_url(@withdraw), as: :json
  #   assert_response :success
  # end

  # test "should update withdraw" do
  #   patch withdraw_url(@withdraw), params: { withdraw: { account_address: @withdraw.account_address, amount: @withdraw.amount, nonce: @withdraw.nonce, signature: @withdraw.signature, token_address: @withdraw.token_address, withdraw_hash: @withdraw.withdraw_hash } }, as: :json
  #   assert_response 200
  # end

  # test "should destroy withdraw" do
  #   assert_difference('Withdraw.count', -1) do
  #     delete withdraw_url(@withdraw), as: :json
  #   end

  #   assert_response 204
  # end
end
