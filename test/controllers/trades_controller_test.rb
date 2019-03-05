require 'test_helper'

class TradesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @OLD_CONTRACT_ADDRESS = ENV['CONTRACT_ADDRESS']
    @OLD_FEE_COLLECTOR_ADDRESS = ENV['FEE_COLLECTOR_ADDRESS']
    @OLD_MAKER_FEE_PERCENTAGE = ENV['MAKER_FEE_PERCENTAGE']
    @OLD_TAKER_FEE_PERCENTAGE = ENV['TAKER_FEE_PERCENTAGE']
    ENV['CONTRACT_ADDRESS'] = '0x4ef6474f40bf5c9dbc013efaac07c4d0cb17219a'
    ENV['FEE_COLLECTOR_ADDRESS'] = '0xcc6cfe1a7f27f84309697beeccbc8112a6b7240a'
    ENV['MAKER_FEE_PERCENTAGE'] = '0.1'
    ENV['TAKER_FEE_PERCENTAGE'] = '0.2'

    @trade = trades(:one)
    @order = orders(:one)
    @fee_account = Account.find_by({ :address => ENV['FEE_COLLECTOR_ADDRESS'] })

    @deposits = batch_deposit([
      { :account_address => @trade.account_address, :token_address => @order.take_token_address, :amount => @order.take_amount },
      { :account_address => @order.account_address, :token_address => @order.give_token_address, :amount => @order.give_amount }
    ])
    @orders = batch_order([
      { :account_address => @order.account_address, :give_token_address => @order.give_token_address, :give_amount => @order.give_amount, :take_token_address => @order.take_token_address, :take_amount => @order.take_amount }
    ])

    @maker_give_balance = @order.account.balance(@order.give_token_address)
    @maker_take_balance = @order.account.balance(@order.take_token_address)
    @taker_give_balance = @trade.account.balance(@order.give_token_address)
    @taker_take_balance = @trade.account.balance(@order.take_token_address)
    @fee_give_balance = @fee_account.balance(@order.give_token_address)
    @fee_take_balance = @fee_account.balance(@order.take_token_address)
  end

  teardown do
    ENV['CONTRACT_ADDRESS'] = @OLD_CONTRACT_ADDRESS
    ENV['FEE_COLLECTOR_ADDRESS'] = @OLD_FEE_COLLECTOR_ADDRESS
    ENV['MAKER_FEE_PERCENTAGE'] = @OLD_MAKER_FEE_PERCENTAGE
    ENV['TAKER_FEE_PERCENTAGE'] = @OLD_TAKER_FEE_PERCENTAGE
  end

  # test "should get index" do
  #   get trades_url, as: :json
  #   assert_response :success
  # end

  test "should create trade, collect fees and swap balances" do
    trade = generate_trade({ :account_address => @trade.account_address, :order_hash => @orders[0].order_hash, :amount => @trade.amount })
    before_trade_balances = [
      { :account_address => @maker_give_balance.account_address, :token_address => @maker_give_balance.token_address, :balance => @maker_give_balance.balance, :hold_balance => @maker_give_balance.hold_balance },
      { :account_address => @maker_take_balance.account_address, :token_address => @maker_take_balance.token_address, :balance => @maker_take_balance.balance, :hold_balance => @maker_take_balance.hold_balance },
      { :account_address => @taker_give_balance.account_address, :token_address => @taker_give_balance.token_address, :balance => @taker_give_balance.balance, :hold_balance => @taker_give_balance.hold_balance },
      { :account_address => @taker_take_balance.account_address, :token_address => @taker_take_balance.token_address, :balance => @taker_take_balance.balance, :hold_balance => @taker_take_balance.hold_balance },
      { :account_address => @fee_give_balance.account_address, :token_address => @fee_give_balance.token_address, :balance => @fee_give_balance.balance, :hold_balance => @fee_give_balance.hold_balance },
      { :account_address => @fee_take_balance.account_address, :token_address => @fee_take_balance.token_address, :balance => @fee_take_balance.balance, :hold_balance => @fee_take_balance.hold_balance }
    ]
    after_trade_balances = [
      { :account_address => @maker_give_balance.account_address, :token_address => @maker_give_balance.token_address, :balance => @maker_give_balance.balance, :hold_balance => @maker_give_balance.hold_balance.to_i - 100000000000000000000 },
      { :account_address => @maker_take_balance.account_address, :token_address => @maker_take_balance.token_address, :balance => @maker_take_balance.balance.to_i + 499500000000000000, :hold_balance => @maker_take_balance.hold_balance },
      { :account_address => @taker_give_balance.account_address, :token_address => @taker_give_balance.token_address, :balance => @taker_give_balance.balance.to_i + 99800000000000000000, :hold_balance => @taker_give_balance.hold_balance },
      { :account_address => @taker_take_balance.account_address, :token_address => @taker_take_balance.token_address, :balance => @taker_take_balance.balance.to_i - 500000000000000000, :hold_balance => @taker_take_balance.hold_balance },
      { :account_address => @fee_give_balance.account_address, :token_address => @fee_give_balance.token_address, :balance => @fee_give_balance.balance.to_i + 200000000000000000, :hold_balance => @fee_give_balance.hold_balance },
      { :account_address => @fee_take_balance.account_address, :token_address => @fee_take_balance.token_address, :balance => @fee_take_balance.balance.to_i + 500000000000000, :hold_balance => @fee_take_balance.hold_balance }
    ]
    before_trade_orders = [
      { :order_hash => @orders[0].order_hash, :filled => 0, :status => "open", :fee => 0 }
    ]
    after_trade_orders = [
      { :order_hash => @orders[0].order_hash, :filled => 100000000000000000000, :status => "closed", :fee => 500000000000000 }
    ]
    after_trade_trades = [
      { :trade_hash => trade[:trade_hash], :fee => 200000000000000000 }
    ]

    assert_model(Balance, before_trade_balances)
    assert_model(Order, before_trade_orders)
    assert_model_nil(Trade, after_trade_trades)

    assert_difference('Trade.count') do
      post trades_url, params: trade, as: :json
    end

    assert_response 201

    assert_model(Balance, after_trade_balances)
    assert_model(Order, after_trade_orders)
    assert_model(Trade, after_trade_trades)
  end

  # test "should show trade" do
  #   get trade_url(@trade), as: :json
  #   assert_response :success
  # end

  # test "should update trade" do
  #   patch trade_url(@trade), params: { trade: { account_address: @trade.account_address, amount: @trade.amount, nonce: @trade.nonce, order_hash: @trade.order_hash, signature: @trade.signature, trade_hash: @trade.trade_hash, uuid: @trade.uuid } }, as: :json
  #   assert_response 200
  # end

  # test "should destroy trade" do
  #   assert_difference('Trade.count', -1) do
  #     delete trade_url(@trade), as: :json
  #   end

  #   assert_response 204
  # end
end
