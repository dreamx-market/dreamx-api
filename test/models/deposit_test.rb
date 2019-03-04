require 'test_helper'

class DepositTest < ActiveSupport::TestCase
  setup do
    @deposit = deposits(:one)
  end

  test "account must exist" do
    assert @deposit.valid?
    @deposit.account_address = 'INVALID'
    assert_not @deposit.valid?
    assert_equal @deposit.errors.messages[:account], ["must exist"]
  end

  test "token must exist" do
    assert @deposit.valid?
    @deposit.token_address = 'INVALID'
    assert_not @deposit.valid?
    assert_equal @deposit.errors.messages[:token], ["must exist"]
  end

  test "amount must be greater than 0" do
    @deposit.amount = 0
    assert_not @deposit.valid?
    assert_equal @deposit.errors.messages[:amount], ["must be greater than 0"]
  end

  test "should credit balance on create" do
    new_deposit = Deposit.new({ :account_address => @deposit.account_address, :token_address => @deposit.token_address, :amount => @deposit.amount })

    before_balances = [
      { :account_address => new_deposit.account_address, :token_address => new_deposit.token_address, :balance => 0, :hold_balance => 0 }
    ]
    after_balances = [
      { :account_address => new_deposit.account_address, :token_address => new_deposit.token_address, :balance => 100000000000000000000, :hold_balance => 0 }
    ]

    assert_model(Balance, before_balances)

    new_deposit.save

    assert_model(Balance, after_balances)
  end
end
