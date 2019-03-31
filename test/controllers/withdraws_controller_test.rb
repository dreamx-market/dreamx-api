require 'test_helper'

class WithdrawsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @old_contract_address = ENV['CONTRACT_ADDRESS']
    ENV['CONTRACT_ADDRESS'] = "0x4ef6474f40bf5c9dbc013efaac07c4d0cb17219a"

    @withdraw = withdraws(:one)

    deposits = [
      { :account_address => @withdraw.account_address, :token_address => @withdraw.token_address, :amount => @withdraw.amount }
    ]
    batch_deposit(deposits)
  end

  teardown do
    ENV['CONTRACT_ADDRESS'] = @old_contract_address
  end

  # test "should get index" do
  #   get withdraws_url, as: :json
  #   assert_response :success
  # end

  # test "should create withdraw and debit balance" do
  #   withdraw = generate_withdraw(@withdraw)
  #   before_balances = [
  #     { :account_address => withdraw[:account_address], :token_address => withdraw[:token_address], :balance => 100000000000000000000, :hold_balance => 0 }
  #   ]
  #   after_balances = [
  #     { :account_address => withdraw[:account_address], :token_address => withdraw[:token_address], :balance => 0, :hold_balance => 0 }
  #   ]
  #   after_withdraws = [
  #     { :withdraw_hash => withdraw[:withdraw_hash], :fee => "1".to_wei }
  #   ]

  #   assert_model(Balance, before_balances)

  #   assert_difference('Withdraw.count') do
  #     post withdraws_url, params: withdraw, as: :json
  #   end

  #   assert_response 201

  #   assert_model(Balance, after_balances)
  #   assert_model(Withdraw, after_withdraws)
  # end

  test "should automatically generate transactions for creation of withdraws" do
    withdraw = generate_withdraw(@withdraw)

    assert_difference('Transaction.count') do
      post withdraws_url, params: withdraw, as: :json
    end

    assert_response 201
  end

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
