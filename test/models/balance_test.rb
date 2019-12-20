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
