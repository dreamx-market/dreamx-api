require 'test_helper'

class WithdrawsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @withdraw = withdraws(:one)
    deposits = [
      { :account_address => @withdraw.account_address, :token_address => @withdraw.token_address, :amount => @withdraw.amount }
    ]
    batch_deposit(deposits)
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

  test "should be consistent with on-chain balance" do
    sync_nonce

    balance = balances(:twenty)
    fee_balance = balances(:fee_four)
    deposits = [
      { :account_address => balance.account_address, :token_address => balance.token_address, :amount => balance.onchain_balance }
    ]
    batch_deposit(deposits)

    assert_equal balance.reload.balance, balance.onchain_balance
    assert_equal fee_balance.reload.balance, fee_balance.onchain_balance

    withdraw = Withdraw.create(generate_withdraw({ :account_address => balance.account_address, :token_address => balance.token_address, :amount => balance.balance }))
    BroadcastTransactionJob.perform_now(withdraw.tx)

    assert_equal balance.reload.balance, balance.onchain_balance
    assert_equal fee_balance.reload.balance, fee_balance.onchain_balance
  end
end
