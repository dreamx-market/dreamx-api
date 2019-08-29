require 'test_helper'

class TradesControllerTest < ActionDispatch::IntegrationTest
  setup do
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

  # test "should get index" do
  #   get trades_url, as: :json
  #   assert_equal json['records'].length, 1
  #   assert_response :success
  # end

  test "get market-specific trades" do
    get trades_url({ :market_symbol => 'ONE_THREE' }), as: :json
    assert_equal json['records'].length, 0
    get trades_url({ :market_symbol => 'ONE_TWO' }), as: :json
    assert_equal json['records'].length, 1
  end

  # test "filtering trades by an account should return both its maker and taker trades" do
  #   # should return all trades where @trade.account_address is either the maker or taker
  #   # should not return another_person's trade
  #   give_token_address = "0x0000000000000000000000000000000000000000"
  #   take_token_address = "0x21921361bab476be44c0655256a2f4281bfcf07d"
  #   amount = "1".to_wei
  #   another_person = addresses[2]
  #   deposits = batch_deposit([
  #     { :account_address => @trade.account_address, :token_address => give_token_address, :amount => amount },
  #     { :account_address => @order.account_address, :token_address => take_token_address, :amount => amount },
  #     { :account_address => another_person, :token_address => @orders[0].take_token_address, :amount => @orders[0].take_amount }
  #   ])
  #   orders = batch_order([
  #     { :account_address => @trade.account_address, :give_token_address => give_token_address, :give_amount => amount, :take_token_address => take_token_address, :take_amount => amount }
  #   ])
  #   trades = batch_trade([
  #     { :account_address => @order.account_address, :order_hash => orders[0].order_hash, :amount => orders[0].give_amount },
  #     { :account_address => another_person, :order_hash => @orders[0].order_hash, :amount => @orders[0].give_amount }
  #   ])
  #   get trades_url({ :account_address => @trade.account_address }), as: :json
  #   assert_equal json['records'].length, 2
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

  # test "should display validation errors when trying to trade a closed order" do
  #   order = @orders[0]
  #   order_cancel = generate_order_cancel({ :order_hash => order.order_hash, :account_address => order.account_address })
  #   trade = generate_trade({ :account_address => @trade.account_address, :order_hash => @orders[0].order_hash, :amount => @orders[0].give_amount })

  #   assert_difference('OrderCancel.count') do
  #     post order_cancels_url, params: [order_cancel], as: :json
  #     assert_equal order.reload.status, 'closed'
  #     assert_response 201
  #   end

  #   assert_no_difference('Trade.count') do
  #     post trades_url, params: [trade], as: :json
  #     assert_equal json['validation_errors'][0], [{"field"=>"order", "reason"=>["must be open"]}]
  #     assert_response 422
  #   end
  # end

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

  # test "should mark balance as fraudulent" do
  #   ENV['FRAUD_PROTECTION'] = 'true'

  #   trade = generate_trade({ :account_address => @trade.account_address, :order_hash => @orders[0].order_hash, :amount => @trade.amount })
  #   balance = @trade.balance
  #   balance.update({ :hold_balance => 1 })
  #   assert_equal balance.reload.fraud, false

  #   assert_no_difference('Trade.count') do
  #     post trades_url, params: [trade], as: :json
  #     assert_equal balance.reload.fraud, true
  #   end

  #   ENV['FRAUD_PROTECTION'] = 'false'
  # end

  # test "should be consistent with on-chain balances" do
  #   give_token = tokens(:one)
  #   take_token = tokens(:four)
  #   give_amount = 195738239776775570
  #   take_amount = 59744193591648150
  #   fill_amount = 163813609331349736

  #   # syncing maker's give balance
  #   maker_give_balance = balances(:four)
  #   batch_withdraw([
  #     { :account_address => maker_give_balance.account_address, :token_address => maker_give_balance.token_address, :amount => maker_give_balance.balance }
  #   ])
  #   batch_deposit([
  #     { :account_address => maker_give_balance.account_address, :token_address => maker_give_balance.token_address, :amount => maker_give_balance.onchain_balance }
  #   ])

  #   # maker's take balance doesn't need syncing because they are both 0
  #   maker_take_balance = balances(:twenty_one)

  #   # syncing taker's give balance
  #   taker_give_balance = balances(:two)
  #   batch_withdraw([
  #     { :account_address => taker_give_balance.account_address, :token_address => taker_give_balance.token_address, :amount => taker_give_balance.balance }
  #   ])
  #   batch_deposit([
  #     { :account_address => taker_give_balance.account_address, :token_address => taker_give_balance.token_address, :amount => taker_give_balance.onchain_balance }
  #   ])

  #   # syncing taker's take balance
  #   taker_take_balance = balances(:twenty)
  #   batch_deposit([
  #     { :account_address => taker_take_balance.account_address, :token_address => taker_take_balance.token_address, :amount => taker_take_balance.onchain_balance }
  #   ])

  #   # syncing make fee collector's balance
  #   fee_give_balance = balances(:fee_one)
  #   fee_give_balance.debit(fee_give_balance.balance)
  #   fee_give_balance.credit(fee_give_balance.onchain_balance)

  #   # syncing take fee collector's balance
  #   fee_take_balance = balances(:fee_four)
  #   fee_take_balance.debit(fee_take_balance.balance)
  #   fee_take_balance.credit(fee_take_balance.onchain_balance)

  #   # before trade assertions
  #   assert_equal maker_give_balance.reload.balance, maker_give_balance.onchain_balance
  #   assert_equal maker_take_balance.reload.balance, maker_take_balance.onchain_balance
  #   assert_equal taker_give_balance.reload.balance, taker_give_balance.onchain_balance
  #   assert_equal taker_take_balance.reload.balance, taker_take_balance.onchain_balance
  #   assert_equal fee_give_balance.reload.balance, fee_give_balance.onchain_balance
  #   assert_equal fee_take_balance.reload.balance, fee_take_balance.onchain_balance

  #   # trade
  #   sync_nonce
  #   order = Order.create(generate_order({ :account_address => maker_give_balance.account_address, :give_token_address => maker_give_balance.token_address, :give_amount => give_amount, :take_token_address => taker_take_balance.token_address, :take_amount => take_amount }))
  #   trade = Trade.create(generate_trade({ :account_address => taker_take_balance.account_address, :order_hash => order.order_hash, :amount => fill_amount }))
  #   BroadcastTransactionJob.perform_now(trade.tx)

  #   # after trade assertions
  #   assert_equal maker_give_balance.reload.balance, maker_give_balance.onchain_balance
  #   assert_equal maker_take_balance.reload.balance, maker_take_balance.onchain_balance
  #   assert_equal taker_give_balance.reload.balance, taker_give_balance.onchain_balance
  #   assert_equal taker_take_balance.reload.balance, taker_take_balance.onchain_balance
  #   assert_equal fee_give_balance.reload.balance, fee_give_balance.onchain_balance
  #   assert_equal fee_take_balance.reload.balance, fee_take_balance.onchain_balance
  # end
end
