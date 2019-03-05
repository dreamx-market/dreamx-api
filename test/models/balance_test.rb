require 'test_helper'

class BalanceTest < ActiveSupport::TestCase
  setup do
    @balance = balances(:three)
    @trade = trades(:one)
    @order = orders(:one)
  end

  # test "balance cannot be negative" do
  #   @balance.balance = -1
  #   assert_not @balance.valid?
  #   assert_equal @balance.errors.messages[:balance], ["must be greater than or equal to 0"]
  # end

  # test "hold_balance cannot be negative" do
  #   @balance.hold_balance = -1
  #   assert_not @balance.valid?
  #   assert_equal @balance.errors.messages[:hold_balance], ["must be greater than or equal to 0"]
  # end

  # test "when balances are authentic" do
  #   @trade.destroy
  #   new_trade = Trade.new(:account_address => @trade.account_address, :order_hash => @trade.order_hash, :amount => @trade.amount, :nonce => @trade.nonce, :trade_hash => @trade.trade_hash, :signature => @trade.signature)
  #   assert new_trade.valid?
  # end

  # test "when balance is compromised because of invalid deposits" do

  # end

  # test "when balance is compromised because of invalid withdraws" do

  # end

  test "when balance is compromised because of invalid trades" do
    # why is 1 wei rounded to 0 ?
    p @order.calculate_take_amount(@trade.amount.to_i + 1000)
    # @trade.amount = @trade.amount.to_i + 1
    # @trade.save(validate: false)
    # p @balance.total_traded
    # assert_not new_trade.valid?
    # assert_equal new_trade.errors.messages[:balance], [ "is compromised"]
  end

  # test "when balance is compromised because of invalid hold_balance" do

  # end
end
