require 'test_helper'

class OrderCancelsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @OLD_CONTRACT_ADDRESS = ENV['CONTRACT_ADDRESS']
    ENV['CONTRACT_ADDRESS'] = '0x4ef6474f40bf5c9dbc013efaac07c4d0cb17219a'

    @order_cancel = order_cancels(:one)
    @order = orders(:two)
    @trade = trades(:one)

    deposit_data = [
      { :account_address => @order.account_address, :token_address => @order.give_token_address, :amount => @order.give_amount },
      { :account_address => @order.account_address, :token_address => @order.give_token_address, :amount => @order.give_amount },
      { :account_address => @order.account_address, :token_address => @order.give_token_address, :amount => @order.give_amount },
      { :account_address => @trade.account_address, :token_address => @order.take_token_address, :amount => @order.take_amount }
    ]
    order_data = [
      { :account_address => @order.account_address, :give_token_address => @order.give_token_address, :give_amount => @order.give_amount, :take_token_address => @order.take_token_address, :take_amount => @order.take_amount },
      { :account_address => @order.account_address, :give_token_address => @order.give_token_address, :give_amount => @order.give_amount, :take_token_address => @order.take_token_address, :take_amount => @order.take_amount },
      { :account_address => @order.account_address, :give_token_address => @order.give_token_address, :give_amount => @order.give_amount, :take_token_address => @order.take_token_address, :take_amount => @order.take_amount }
    ]
    @deposits = batch_deposit(deposit_data)
    @orders = batch_order(order_data)
  end

  teardown do
    ENV['CONTRACT_ADDRESS'] = @OLD_CONTRACT_ADDRESS
  end

  test "should create order_cancel and refund" do
    @order_cancel.order_hash = @orders[0].order_hash
    order_cancel = [generate_order_cancel(@order_cancel)]

    before_cancel_balances = [
      { :account_address => @orders[0].account_address, :token_address => @orders[0].give_token_address, :balance => 100000000000000000000, :hold_balance => 300000000000000000000 }
    ]
    after_cancel_balances = [
      { :account_address => @orders[0].account_address, :token_address => @orders[0].give_token_address, :balance => 200000000000000000000, :hold_balance => 200000000000000000000 }
    ]
    before_cancel_orders = [
      { :order_hash => @orders[0].order_hash, :status => "open" }
    ]
    after_cancel_orders = [
      { :order_hash => @orders[0].order_hash, :status => "closed" } 
    ]

    assert_model(Balance, before_cancel_balances)
    assert_model(Order, before_cancel_orders)

    assert_difference('OrderCancel.count') do
      post order_cancels_url, params: order_cancel, as: :json
    end

    assert_response 201

    assert_model(Balance, after_cancel_balances)
    assert_model(Order, after_cancel_orders)
  end

  test "should cancel a partially filled order and refund" do
    @order_cancel.order_hash = @orders[0].order_hash
    order_cancel = [generate_order_cancel(@order_cancel)]

    trade_data = [
      { **@trade.as_json.symbolize_keys, :order_hash => @orders[0].order_hash, :amount => @trade.amount.to_i / 2 }
    ]
    trades = batch_trade(trade_data)

    before_cancel_balances = [
      { :account_address => @orders[0].account_address, :token_address => @orders[0].give_token_address, :balance => 100000000000000000000, :hold_balance => 250000000000000000000 }
    ]
    after_cancel_balances = [
      { :account_address => @orders[0].account_address, :token_address => @orders[0].give_token_address, :balance => 150000000000000000000, :hold_balance => 200000000000000000000 }
    ]
    before_cancel_orders = [
      { :order_hash => @orders[0].order_hash, :status => "partially_filled" }
    ]
    after_cancel_orders = [
      { :order_hash => @orders[0].order_hash, :status => "closed" } 
    ]

    assert_model(Balance, before_cancel_balances)
    assert_model(Order, before_cancel_orders)

    assert_difference('OrderCancel.count') do
      post order_cancels_url, params: order_cancel, as: :json
    end

    assert_response 201

    assert_model(Balance, after_cancel_balances)
    assert_model(Order, after_cancel_orders)
  end

  test "should batch cancel" do
    order_cancels = []
    @orders.each do |order|
      order_cancels.push(generate_order_cancel({ :order_hash => order.order_hash, :account_address => order.account_address }))
    end

    before_cancel_balances = [
      { :account_address => @orders[0].account_address, :token_address => @orders[0].give_token_address, :balance => 100000000000000000000, :hold_balance => 300000000000000000000 }
    ]
    after_cancel_balances = [
      { :account_address => @orders[0].account_address, :token_address => @orders[0].give_token_address, :balance => 400000000000000000000, :hold_balance => 0 }
    ]
    before_cancel_orders = [
      { :order_hash => @orders[0].order_hash, :status => "open" },
      { :order_hash => @orders[1].order_hash, :status => "open" },
      { :order_hash => @orders[2].order_hash, :status => "open" }
    ]
    after_cancel_orders = [
      { :order_hash => @orders[0].order_hash, :status => "closed" },
      { :order_hash => @orders[1].order_hash, :status => "closed" },
      { :order_hash => @orders[2].order_hash, :status => "closed" }
    ]

    assert_model(Balance, before_cancel_balances)
    assert_model(Order, before_cancel_orders)

    assert_changes('OrderCancel.count') do
      post order_cancels_url, params: order_cancels, as: :json
    end

    assert_model(Balance, after_cancel_balances)
    assert_model(Order, after_cancel_orders)
  end

  # test "should rollback if there are errors" do
  # end

  test "should display validation errors" do
    order_cancels = []
    @orders.each do |order|
      order_cancels.push(generate_order_cancel({ :order_hash => order.order_hash, :account_address => order.account_address }))
    end
    order_cancels[0][:account_address] = 'INVALID'
    order_cancels[1][:order_hash] = 'INVALID'
    order_cancels[2][:signature] = 'INVALID'

    post order_cancels_url, params: order_cancels, as: :json
    order_one_error = json["validation_errors"][0].select { |error| error['field'] === 'account' }[0]['reason']
    order_two_error = json["validation_errors"][1].select { |error| error['field'] === 'order' }[0]['reason']
    order_three_error = json["validation_errors"][2].select { |error| error['field'] === 'signature' }[0]['reason']

    assert_equal order_one_error, ['must exist']
    assert_equal order_two_error, ['must exist']
    assert_equal order_three_error, ['invalid']
  end
end
