require 'test_helper'

class WithdrawsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @old_contract_address = ENV['CONTRACT_ADDRESS'].without_checksum
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

  test "should create withdraw and debit balance" do
    withdraw = generate_withdraw({ :account_address => @withdraw.account_address, :token_address => @withdraw.token_address, :amount => @withdraw.amount })
    before_balances = [
      { :account_address => withdraw[:account_address], :token_address => withdraw[:token_address], :balance => 100000000000000000000, :hold_balance => 0 }
    ]
    after_balances = [
      { :account_address => withdraw[:account_address], :token_address => withdraw[:token_address], :balance => 0, :hold_balance => 0 }
    ]
    after_withdraws = [
      { :withdraw_hash => withdraw[:withdraw_hash], :fee => "1".to_wei }
    ]

    assert_model(Balance, before_balances)

    assert_difference('Withdraw.count') do
      post withdraws_url, params: withdraw, as: :json
    end

    assert_response 201

    assert_model(Balance, after_balances)
    assert_model(Withdraw, after_withdraws)
  end

  test "should automatically generate transactions for creation of withdraws" do
    withdraw = generate_withdraw({ :account_address => @withdraw.account_address, :token_address => @withdraw.token_address, :amount => @withdraw.amount })

    assert_difference('Transaction.count') do
      post withdraws_url, params: withdraw, as: :json
    end

    assert_response 201
  end

  test "mark balance as fraudulent if it is unauthentic" do
    ENV['FRAUD_PROTECTION'] = 'true'
    withdraw = generate_withdraw({ :account_address => @withdraw.account_address, :token_address => @withdraw.token_address, :amount => @withdraw.amount })
    balance = @withdraw.account.balance(@withdraw.token_address)
    balance.update({ :hold_balance => '123' })
    post withdraws_url, params: withdraw, as: :json
    assert_equal balance.reload.fraud, true
    ENV['FRAUD_PROTECTION'] = 'false'
  end
end
