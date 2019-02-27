require 'test_helper'

class BalanceTest < ActiveSupport::TestCase
  setup do
    @balance = balances(:one)
  end

  test "balance cannot be negative" do
    @balance.balance = -1
    assert_not @balance.valid?
    assert_equal @balance.errors.messages[:balance], ["must be greater than or equal to 0"]
  end

  test "hold_balance cannot be negative" do
    @balance.hold_balance = -1
    assert_not @balance.valid?
    assert_equal @balance.errors.messages[:hold_balance], ["must be greater than or equal to 0"]
  end
end
