require 'test_helper'

class RefundTest < ActiveSupport::TestCase
  setup do
    @balance = balances(:one)
  end

  test "reverses balance upon being destroyed" do
    assert_equal @balance.balance, '0'
    @balance.refund('1'.to_wei)
    assert_equal @balance.reload.balance, '1'.to_wei
    @balance.refunds.last.destroy
    assert_equal @balance.reload.balance, '0'
  end
end
