require 'test_helper'

class BalanceTest < ActiveSupport::TestCase
  setup do
    @trade = trades(:one)
    @order = orders(:three)
    @withdraw = withdraws(:one)
    @deposit = deposits(:one)
    @maker = balances(:eight)
    @taker = balances(:nine)
    @give_token = tokens(:one)
    @take_token = tokens(:two)
  end

  test "balance cannot be negative" do
    balance = Balance.last
    balance.balance = -1
    assert_not balance.valid?
    assert_equal balance.errors.messages[:balance], ["must be greater than or equal to 0"]
  end

  test "hold_balance cannot be negative" do
    balance = Balance.last
    balance.hold_balance = -1
    assert_not balance.valid?
    assert_equal balance.errors.messages[:hold_balance], ["must be greater than or equal to 0"]
  end

  test "when balances are authentic" do
    assert @maker.authentic?

    deposits = batch_deposit([
      { :account_address => @maker.account_address, :token_address => @give_token.address, :amount => "1".to_wei },
      { :account_address => @taker.account_address, :token_address => @take_token.address, :amount => "0.6".to_wei }
    ])
    orders = batch_order([
      { :account_address => @maker.account_address, :give_token_address => @give_token.address, :give_amount => "0.5".to_wei, :take_token_address => @take_token.address, :take_amount => "0.3".to_wei }
    ])
    trades = batch_trade([
      { :account_address => @taker.account_address, :order_hash => orders[0].order_hash, :amount => "0.4".to_wei }
    ])
    withdraws = batch_withdraw([
      { :account_address => @maker.account_address, :token_address => @give_token.address, :amount => "0.5".to_wei },
    ])

    @maker.reload
    assert @maker.authentic?
  end

  test "when balance is compromised because of invalid deposits" do
    balance = @deposit.account.balance(@deposit.token_address)
    assert balance.authentic?

    @deposit.amount = @deposit.amount.to_i * 2
    @deposit.save(validate: false)

    assert_not balance.authentic?
    assert_equal balance.fraud, true
    assert_equal ENV['READONLY'], 'true'
    # always reset environment variables back to its initial state
    ENV['READONLY'] = 'false'
  end

  test "when balance is compromised because of invalid withdraws" do
    balance = @withdraw.account.balance(@withdraw.token_address)
    assert balance.authentic?

    @withdraw.amount = @withdraw.amount.to_i * 2
    @withdraw.save(validate: false)

    assert_not balance.authentic?
    assert_equal balance.fraud, true
    assert_equal ENV['READONLY'], 'true'
    # always reset environment variables back to its initial state
    ENV['READONLY'] = 'false'
  end

  test "when balance is compromised because of invalid trades" do
    balance = @trade.account.balance(@trade.order.give_token_address)
    assert balance.authentic?

    @trade.amount = @trade.amount.to_i * 2
    @trade.save(validate: false)

    assert_not balance.authentic?
    assert_equal balance.fraud, true
    assert_equal ENV['READONLY'], 'true'
    # always reset environment variables back to its initial state
    ENV['READONLY'] = 'false'
  end

  test "when balance is compromised because of invalid hold_balance" do
    balance = Balance.last
    assert balance.authentic?

    balance.hold_balance = '1234'
    balance.save(validate: false)

    assert_not balance.authentic?
    assert_equal balance.fraud, true
    assert_equal ENV['READONLY'], 'true'
    # always reset environment variables back to its initial state
    ENV['READONLY'] = 'false'
  end

  test "when balance is compromised because of invalid open orders" do
    balance = @order.account.balance(@order.give_token_address)
    assert balance.authentic?

    @order.give_amount = @order.give_amount.to_i * 2
    @order.save(validate: false)

    assert_not balance.authentic?
    assert_equal balance.fraud, true
    assert_equal ENV['READONLY'], 'true'
    # always reset environment variables back to its initial state
    ENV['READONLY'] = 'false'
  end
end
