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
    @balance = balances(:one)
  end

  test "total_traded is calculated correctly for buy orders with multiple trades" do
    maker = @taker
    taker = @maker
    maker_receiving_balance = Balance.find_by({ :account_address => maker.account_address, :token_address => taker.token_address })
    deposits = batch_deposit([
      { :account_address => maker.account_address, :token_address => maker.token_address, :amount => "1".to_wei },
      { :account_address => taker.account_address, :token_address => taker.token_address, :amount => "1".to_wei }
    ])
    order = Order.create(generate_order({ :account_address => maker.account_address, :give_token_address => maker.token_address, :give_amount => "51753042574917310", :take_token_address => taker.token_address, :take_amount => "157876344711646175" }))
    trades = batch_trade([
      { :account_address => taker.account_address, :order_hash => order.order_hash, :amount => "19043091019761810" },
      { :account_address => taker.account_address, :order_hash => order.order_hash, :amount => "32709951555155500" }
    ])
    assert_equal maker_receiving_balance.reload.balance.to_i, maker_receiving_balance.total_traded.to_i
  end

  test "should not invalidate on refunds" do
    assert @balance.authentic?
    @balance.refund("1".to_wei)
    assert @balance.reload.authentic?
  end

  test ".closed_and_partially_filled_buy_orders and .sell_trades preloads trades and orders" do
    # a_token_balance has at least:
    # 1 deposit
    # 1 refund
    # 1 open sell order
    # 1 closed sell order
    # 1 closed buy order
    # 1 sell trade
    # 1 buy trade

    a_token_balance = balances(:one)
    a_eth_balance = balances(:two)
    b_token_balance = balances(:three)
    b_eth_balance = balances(:four)
    eth_address = a_eth_balance.token_address
    token_address = a_token_balance.token_address
    a_address = a_token_balance.account_address
    b_address = b_token_balance.account_address

    a_token_deposit = { account_address: a_address, token_address: token_address, amount: '10'.to_wei }
    a_eth_deposit = { account_address: a_address, token_address: eth_address, amount: '10'.to_wei }
    a_sell_order = { account_address: a_address, give_token_address: token_address, give_amount: '0.3'.to_wei, take_token_address: eth_address, take_amount: '1'.to_wei }
    a_buy_order = { account_address: a_address, give_token_address: eth_address, give_amount: '1'.to_wei, take_token_address: token_address, take_amount: '0.3'.to_wei }

    b_sell_order = { account_address: b_address, give_token_address: token_address, give_amount: '0.3'.to_wei, take_token_address: eth_address, take_amount: '1'.to_wei }
    b_buy_order = { account_address: b_address, give_token_address: eth_address, give_amount: '0.3'.to_wei, take_token_address: token_address, take_amount: '1'.to_wei }

    created_deposits = []
    created_orders = []
    assert_changes("a_token_balance.balance") do
    assert_changes("a_eth_balance.balance") do
      created_deposits = batch_deposit([a_token_deposit, a_token_deposit, a_token_deposit, a_eth_deposit])
      created_orders = batch_order([a_sell_order, a_sell_order, a_buy_order, b_sell_order, b_buy_order])
      a_token_balance.reload
      a_eth_balance.reload
    end
    end

    assert_difference("Refund.count", 1) do
      a_token_balance.refund("1".to_wei)
    end

    a_buy_trade = { account_address: a_address, order_hash: created_orders[3].order_hash, amount: created_orders[3].give_amount }
    a_sell_trade = { account_address: a_address, order_hash: created_orders[4].order_hash, amount: created_orders[4].give_amount }
    b_buy_trade = { account_address: b_address, order_hash: created_orders[1].order_hash, amount: created_orders[1].give_amount }
    b_sell_trade = { account_address: b_address, order_hash: created_orders[2].order_hash, amount: created_orders[2].give_amount }

    assert_difference("Trade.count", 4) do
      batch_trade([a_buy_trade, a_sell_trade, b_buy_trade, b_sell_trade])
    end

    assert_equal a_token_balance.closed_and_partially_filled_buy_orders[0].association(:trades).loaded?, true
    assert_equal a_token_balance.sell_trades[0].association(:order).loaded?, true
  end

  test "balance altering operations should be thread-safe" do
    assert_equal ActiveRecord::Base.connection.pool.size, 5

    threads = []
    3.times do
      thread = Thread.new do
        @balance.credit(1)
      end
      threads.push(thread)
    end
    threads.each(&:join)
    assert_equal @balance.reload.balance.to_i, 3

    threads = []
    3.times do
      thread = Thread.new do
        @balance.debit(1)
      end
      threads.push(thread)
    end
    threads.each(&:join)
    assert_equal @balance.reload.balance.to_i, 0

    threads = []
    3.times do
      thread = Thread.new do
        @balance.credit(1)
        @balance.hold(1)
      end
      threads.push(thread)
    end
    threads.each(&:join)
    assert_equal @balance.reload.hold_balance.to_i, 3

    threads = []
    3.times do
      thread = Thread.new do
        @balance.spend(1)
      end
      threads.push(thread)
    end
    threads.each(&:join)
    assert_equal @balance.reload.hold_balance.to_i, 0

    threads = []
    3.times do
      thread = Thread.new do
        @balance.credit(1)
        @balance.hold(1)
        @balance.release(1)
      end
      threads.push(thread)
    end
    threads.each(&:join)
    assert_equal @balance.reload.balance.to_i, 3
    assert_equal @balance.reload.hold_balance.to_i, 0
  end

  test "creating refunds should be thread-safe" do
    concurrently do
      @balance.refund(1)
    end

    assert_equal @balance.reload.balance.to_i, 4
  end
end
