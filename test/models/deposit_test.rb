require 'test_helper'

class DepositTest < ActiveSupport::TestCase
  setup do
    @deposit = deposits(:one)
    @balance = balances(:one)
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

    after_balances = [
      { :account_address => new_deposit.account_address, :token_address => new_deposit.token_address, :balance => @balance.balance.to_i + 100000000000000000000, :hold_balance => @balance.hold_balance }
    ]

    new_deposit.save

    assert_model(Balance, after_balances)
  end

  test "should aggregate new deposits" do
    # remove the existing account and balance so they can be re-initialize
    balance = Balance.find_by({ account_address: '0xa77344043e0b0bada9318f41803e07e9dfc57b0b', token_address: '0x0000000000000000000000000000000000000000' })
    account = balance.account
    account.destroy

    assert_difference('Account.count') do
    assert_difference('Balance.count') do
    assert_difference('Deposit.count') do
      Deposit.aggregate(9)
    end
    end
    end
  end

  test "transaction_hash must be unique" do
    new_deposit = Deposit.new({ :transaction_hash => @deposit.transaction_hash })
    assert_not new_deposit.valid?
    assert_equal new_deposit.errors.messages[:transaction_hash], ["has already been taken"]
  end
end
