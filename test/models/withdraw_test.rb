require 'test_helper'

class WithdrawTest < ActiveSupport::TestCase
   setup do
    @old_contract_address = ENV['CONTRACT_ADDRESS'].without_checksum
    ENV['CONTRACT_ADDRESS'] = "0x4ef6474f40bf5c9dbc013efaac07c4d0cb17219a"

    @withdraw = withdraws(:one)
    @balance = balances(:one)
  end

  teardown do
    ENV['CONTRACT_ADDRESS'] = @old_contract_address
  end

  test "account must exist" do
    assert @withdraw.valid?
    @withdraw.account_address = 'INVALID'
    assert_not @withdraw.valid?
    assert_equal @withdraw.errors.messages[:account], ["must exist"]
  end

  test "token must exist" do
    assert @withdraw.valid?
    @withdraw.token_address = 'INVALID'
    assert_not @withdraw.valid?
    assert_equal @withdraw.errors.messages[:token], ["must exist"]
  end

  test "nonce must be valid" do
    new_withdraw = Withdraw.new({ :account_address => @withdraw.account_address, :token_address => @withdraw.token_address, :nonce => 1 })
    assert_not new_withdraw.valid?
    assert_equal new_withdraw.errors.messages[:nonce], ['must be greater than last nonce']
  end

  test "account must have sufficient balance" do
    new_withdraw = Withdraw.new({ :account_address => @withdraw.account_address, :token_address => @withdraw.token_address, :amount => @withdraw.amount })
    new_withdraw.amount = new_withdraw.amount.to_i + 1
    assert_not new_withdraw.valid?
    assert_equal new_withdraw.errors.messages[:account_address], ['insufficient balance']
  end

  test "amount must be greater than minimum volume" do
    @withdraw.amount = 0
    assert_not @withdraw.valid?
    assert_equal @withdraw.errors.messages[:amount], ["must be greater than #{@withdraw.token.withdraw_minimum.to_ether}"]
  end

  test "withdraw_hash must be valid" do
    @withdraw.withdraw_hash = 'INVALID'
    assert_not @withdraw.valid?
    assert_equal @withdraw.errors.messages[:withdraw_hash], ['invalid']
  end

  test "signature must be valid" do
    @withdraw.signature = 'INVALID'
    assert_not @withdraw.valid?
    assert_equal @withdraw.errors.messages[:signature], ['invalid']
  end

  test "has a transaction" do
    assert_not_nil @withdraw.tx
  end

  test "withdraw_hash must be unique" do
    new_withdraw = Withdraw.new({ :withdraw_hash => @withdraw.withdraw_hash })
    assert_not new_withdraw.valid?
    assert new_withdraw.errors.messages[:withdraw_hash].include?('has already been taken')
  end

  test "refunds entire withdrawal when amount is greater than onchain balance" do
    mock_balance_onchain_balance = '2'.to_wei
    deposit_amount = '1'.to_wei
    batch_deposit([
      { :account_address => @balance.account_address, :token_address => @balance.token_address, :amount => deposit_amount }
    ])
    withdraw = batch_withdraw([
      { :account_address => @balance.account_address, :token_address => @balance.token_address, :amount => deposit_amount }
    ]).first
    withdraw.mock_balance_onchain_balance = mock_balance_onchain_balance
    withdraw.refund
    assert_equal withdraw.balance.reload.balance, "1".to_wei
  end

  test "refunds the difference between withdrawal and onchain balance when amount is lesser than onchain balance" do
    mock_balance_onchain_balance = '0.5'.to_wei
    deposit_amount = '1'.to_wei
    batch_deposit([
      { :account_address => @balance.account_address, :token_address => @balance.token_address, :amount => deposit_amount }
    ])
    withdraw = batch_withdraw([
      { :account_address => @balance.account_address, :token_address => @balance.token_address, :amount => deposit_amount }
    ]).first
    withdraw.mock_balance_onchain_balance = mock_balance_onchain_balance
    withdraw.refund
    assert_equal withdraw.balance.reload.balance, "0.5".to_wei    
  end
end
