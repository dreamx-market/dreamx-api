require 'test_helper'

class TradesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @OLD_CONTRACT_ADDRESS = ENV['CONTRACT_ADDRESS'].without_checksum
    @OLD_FEE_COLLECTOR_ADDRESS = ENV['FEE_COLLECTOR_ADDRESS'].without_checksum
    @OLD_MAKER_FEE_PERCENTAGE = ENV['MAKER_FEE_PERCENTAGE']
    @OLD_TAKER_FEE_PERCENTAGE = ENV['TAKER_FEE_PERCENTAGE']
    ENV['CONTRACT_ADDRESS'] = '0x4ef6474f40bf5c9dbc013efaac07c4d0cb17219a'
    ENV['FEE_COLLECTOR_ADDRESS'] = '0xcc6cfe1a7f27f84309697beeccbc8112a6b7240a'
    ENV['MAKER_FEE_PERCENTAGE'] = '0.1'
    ENV['TAKER_FEE_PERCENTAGE'] = '0.2'

    @trade = trades(:one)
    @order = orders(:one)
    @fee_account = Account.find_by({ :address => ENV['FEE_COLLECTOR_ADDRESS'].without_checksum })

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

  # test "should create trade, collect fees and swap balances" do
  #   trade = generate_trade({ :account_address => @trade.account_address, :order_hash => @orders[0].order_hash, :amount => @trade.amount })
  #   before_trade_balances = [
  #     { :account_address => @maker_give_balance.account_address, :token_address => @maker_give_balance.token_address, :balance => @maker_give_balance.balance, :hold_balance => @maker_give_balance.hold_balance },
  #     { :account_address => @maker_take_balance.account_address, :token_address => @maker_take_balance.token_address, :balance => @maker_take_balance.balance, :hold_balance => @maker_take_balance.hold_balance },
  #     { :account_address => @taker_give_balance.account_address, :token_address => @taker_give_balance.token_address, :balance => @taker_give_balance.balance, :hold_balance => @taker_give_balance.hold_balance },
  #     { :account_address => @taker_take_balance.account_address, :token_address => @taker_take_balance.token_address, :balance => @taker_take_balance.balance, :hold_balance => @taker_take_balance.hold_balance },
  #     { :account_address => @fee_give_balance.account_address, :token_address => @fee_give_balance.token_address, :balance => @fee_give_balance.balance, :hold_balance => @fee_give_balance.hold_balance },
  #     { :account_address => @fee_take_balance.account_address, :token_address => @fee_take_balance.token_address, :balance => @fee_take_balance.balance, :hold_balance => @fee_take_balance.hold_balance }
  #   ]
  #   after_trade_balances = [
  #     { :account_address => @maker_give_balance.account_address, :token_address => @maker_give_balance.token_address, :balance => @maker_give_balance.balance, :hold_balance => @maker_give_balance.hold_balance.to_i - 100000000000000000000 },
  #     { :account_address => @maker_take_balance.account_address, :token_address => @maker_take_balance.token_address, :balance => @maker_take_balance.balance.to_i + 499500000000000000, :hold_balance => @maker_take_balance.hold_balance },
  #     { :account_address => @taker_give_balance.account_address, :token_address => @taker_give_balance.token_address, :balance => @taker_give_balance.balance.to_i + 99800000000000000000, :hold_balance => @taker_give_balance.hold_balance },
  #     { :account_address => @taker_take_balance.account_address, :token_address => @taker_take_balance.token_address, :balance => @taker_take_balance.balance.to_i - 500000000000000000, :hold_balance => @taker_take_balance.hold_balance },
  #     { :account_address => @fee_give_balance.account_address, :token_address => @fee_give_balance.token_address, :balance => @fee_give_balance.balance.to_i + 200000000000000000, :hold_balance => @fee_give_balance.hold_balance },
  #     { :account_address => @fee_take_balance.account_address, :token_address => @fee_take_balance.token_address, :balance => @fee_take_balance.balance.to_i + 500000000000000, :hold_balance => @fee_take_balance.hold_balance }
  #   ]
  #   before_trade_orders = [
  #     { :order_hash => @orders[0].order_hash, :filled => 0, :status => "open", :fee => 0 }
  #   ]
  #   after_trade_orders = [
  #     { :order_hash => @orders[0].order_hash, :filled => 100000000000000000000, :status => "closed", :fee => 500000000000000 }
  #   ]
  #   after_trade_trades = [
  #     { :trade_hash => trade[:trade_hash], :fee => 200000000000000000 }
  #   ]

  #   assert_model(Balance, before_trade_balances)
  #   assert_model(Order, before_trade_orders)
  #   assert_model_nil(Trade, after_trade_trades)

  #   assert_difference('Trade.count') do
  #     post trades_url, params: [trade], as: :json
  #   end

  #   assert_response 201

  #   assert_model(Balance, after_trade_balances)
  #   assert_model(Order, after_trade_orders)
  #   assert_model(Trade, after_trade_trades)
  # end

  # test "should generate transaction" do
  #   trade = generate_trade({ :account_address => @trade.account_address, :order_hash => @orders[0].order_hash, :amount => @trade.amount })

  #   assert_difference('Transaction.count') do
  #     post trades_url, params: [trade], as: :json
  #   end

  #   assert_response 201
  # end

  # test "should batch trade" do
  #   trades = []
  #   3.times do
  #     trades << generate_trade({ :account_address => @trade.account_address, :order_hash => @orders[0].order_hash, :amount => @trade.amount.to_i / 3 })
  #   end

  #   assert_difference('Trade.count', 3) do
  #     post trades_url, params: trades, as: :json
  #   end
  # end

  test "should display validation errors when trying to trade a closed order" do
    order = @orders[0]
    order_cancel = generate_order_cancel({ :order_hash => order.order_hash, :account_address => order.account_address })
    trade = generate_trade({ :account_address => @trade.account_address, :order_hash => @orders[0].order_hash, :amount => @orders[0].give_amount })

    assert_difference('OrderCancel.count') do
      post order_cancels_url, params: [order_cancel], as: :json
      assert_equal order.reload.status, 'closed'
      assert_response 201
    end

    assert_no_difference('Trade.count') do
      post trades_url, params: [trade], as: :json
      assert_equal json['validation_errors'][0], [{"field"=>"order", "reason"=>["must be open"]}]
      assert_response 422
    end
  end

  # test "should rollback batch trade if a trade failed to save" do
  #   trades = []
  #   3.times do
  #     trades << generate_trade({ :account_address => @trade.account_address, :order_hash => @orders[0].order_hash, :amount => @trade.amount.to_i / 3 })
  #   end
  #   trades.last[:signature] = 'INVALID'

  #   assert_no_difference('Trade.count') do
  #     post trades_url, params: trades, as: :json
  #   end
  # end

  # test "trade_balances should initialize balances if not exist" do
  #   # create a new maker and taker accounts, top up, create maker's order and taker's trade
  #   fee_address = ENV['FEE_COLLECTOR_ADDRESS'].without_checksum
  #   maker_address = addresses[7]
  #   taker_address = addresses[8]
  #   give_token_address = "0x21921361bab476be44c0655256a2f4281bfcf07d"
  #   take_token_address = "0x0000000000000000000000000000000000000000"
  #   give_amount = "100000000000000000000"
  #   take_amount = "100000000000000000000"
  #   Account.initialize_if_not_exist(maker_address, give_token_address)
  #   Account.initialize_if_not_exist(taker_address, take_token_address)
  #   deposits = batch_deposit([
  #     { :account_address => maker_address, :token_address => give_token_address, :amount => give_amount },
  #     { :account_address => taker_address, :token_address => take_token_address, :amount => take_amount }
  #   ])
  #   orders = batch_order([
  #     { :account_address => maker_address, :give_token_address => give_token_address, :give_amount => give_amount, :take_token_address => take_token_address, :take_amount => take_amount }
  #   ])
  #   trade = generate_trade({ :account_address => taker_address, :order_hash => orders[0].order_hash, :amount => give_amount })
  #   # delete fee give and take balances
  #   Balance.find_by({ :account_address => fee_address, :token_address => give_token_address }).destroy
  #   Balance.find_by({ :account_address => fee_address, :token_address => take_token_address }).destroy
  #   # fee give/take, maker take, taker give don't exist before the trade
  #   fee_give_balance = Balance.find_by({ :account_address => fee_address, :token_address => give_token_address })
  #   fee_take_balance = Balance.find_by({ :account_address => fee_address, :token_address => take_token_address })
  #   maker_take_balance = Balance.find_by({ :account_address => maker_address, :token_address => take_token_address })
  #   taker_give_balance = Balance.find_by({ :account_address => taker_address, :token_address => give_token_address })
  #   assert_nil fee_give_balance
  #   assert_nil fee_take_balance
  #   assert_nil maker_take_balance
  #   assert_nil taker_give_balance
  #   # fee give/take, maker take, taker give are created after the trade
  #   assert_difference("Balance.count", 4) do
  #     post trades_url, params: [trade], as: :json
  #     fee_give_balance = Balance.find_by({ :account_address => fee_address, :token_address => give_token_address })
  #     fee_take_balance = Balance.find_by({ :account_address => fee_address, :token_address => take_token_address })
  #     maker_take_balance = Balance.find_by({ :account_address => maker_address, :token_address => take_token_address })
  #     taker_give_balance = Balance.find_by({ :account_address => taker_address, :token_address => give_token_address })
  #     assert_not_nil fee_give_balance
  #     assert_not_nil fee_take_balance
  #     assert_not_nil maker_take_balance
  #     assert_not_nil taker_give_balance
  #   end
  # end

  # test "should close sell order after trade if remaining volume doesnt meet taker minimum" do
  #   order = @orders[0]
  #   trade = generate_trade({ :account_address => @trade.account_address, :order_hash => order.order_hash, :amount => "91".to_wei })

  #   assert_equal order.reload.status, 'open'

  #   assert_difference('Trade.count') do
  #     post trades_url, params: [trade], as: :json
  #     assert_response 201
  #     assert_equal order.reload.status, 'closed'
  #   end
  # end

  # test "should close buy order after trade if remaining volume doesnt meet taker minimum" do
  #   deposits = batch_deposit([
  #     { :account_address => @order.account_address, :token_address => @order.give_token_address, :amount => "1".to_wei },
  #     { :account_address => @order.account_address, :token_address => @order.take_token_address, :amount => "1".to_wei }
  #   ])
  #   orders = batch_order([
  #     { :account_address => @order.account_address, :give_token_address => @order.take_token_address, :give_amount => "1".to_wei, :take_token_address => @order.give_token_address, :take_amount => "1".to_wei }
  #   ])
  #   trade = generate_trade({ :account_address => @order.account_address, :order_hash => orders[0].order_hash, :amount => "0.96".to_wei })

  #   assert_not orders[0].is_sell
  #   assert_equal orders[0].reload.status, 'open'

  #   assert_difference('Trade.count') do
  #     post trades_url, params: [trade], as: :json
  #     assert_response 201
  #     assert_equal orders[0].reload.status, 'closed'
  #   end
  # end
end
