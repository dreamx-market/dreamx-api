require 'test_helper'

class AccountTest < ActiveSupport::TestCase
  setup do
    @balance = balances(:one)
    @account = @balance.account
  end

  test "initializing should not reset existing balances to 0" do
    existing_balance = Balance.find_by({ :account_address => "0xfa46ed8f8d3f15e7d820e7246233bbd9450903e3", :token_address => "0x21921361bab476be44c0655256a2f4281bfcf07d" })
    batch_deposit([
      { :account_address => existing_balance.account_address, :token_address => existing_balance.token_address, :amount => 10 }
    ])
    existing_balance.reload
    assert_no_changes("existing_balance.balance") do
      Balance.find_or_create_by({ account_address: existing_balance.account_address, token_address: existing_balance.token_address })
      existing_balance.reload
    end
  end

  test "successfully eject an account" do
    sync_nonce
    exchange = Contract::Exchange.singleton.instance
    balance = balances(:one)
    account = balance.account
    eth = tokens(:one)
    eth_address = eth.address
    token_address = balance.token_address
    deposit = { account_address: account.address, token_address: token_address, amount: '10'.to_wei }
    order = { account_address: account.address, give_token_address: token_address, give_amount: '0.1'.to_wei, take_token_address: eth_address, take_amount: '1'.to_wei }

    assert_difference("balance.reload.open_orders.count", 3) do
      batch_deposit([deposit])
      batch_order([order, order, order])
    end

    assert_changes("account.reload.ejected") do
    assert_difference("Ejection.count", 1) do
    assert_difference("Transaction.count", 1) do
    assert_difference("balance.reload.open_orders.count", -3) do
    assert_difference("balance.reload.closed_orders.count", 3) do
    assert_difference("Redis.current.get('nonce').to_i") do
      account.eject
    end
    end
    end
    end
    end
    end

    ejection = Ejection.find_by({ account_address: account.address })

    BroadcastTransactionJob.perform_now(ejection.tx)
    assert_equal exchange.call.account_manual_withdraws(account.address), true

    Transaction.confirm_mined_transactions
    assert_equal ejection.reload.tx.status, 'confirmed'
  end
end
