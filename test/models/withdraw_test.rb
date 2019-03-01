require 'test_helper'

class WithdrawTest < ActiveSupport::TestCase
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
    new_withdraw = Withdraw.new({ :nonce => 1 })
    assert_not new_withdraw.valid?
    assert_equal new_withdraw.errors.messages[:nonce], ['must be greater than last nonce']
  end

  test "account must have sufficient balance" do
    @withdraw.amount = @withdraw.amount.to_i + 1
    assert_not @withdraw.valid?
    assert_equal @withdraw.errors.messages[:account_address], ['insufficient balance']
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
end