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

  test "should generate transaction" do
    trade = generate_trade({ :account_address => @trade.account_address, :order_hash => @orders[0].order_hash, :amount => @trade.amount })

    assert_difference('Transaction.count') do
      post trades_url, params: [trade], as: :json
    end

    assert_response 201
  end

  test "should batch trades" do
    trades = []
    3.times do
      trades << generate_trade({ :account_address => @trade.account_address, :order_hash => @orders[0].order_hash, :amount => @trade.amount.to_i / 3 })
    end

    assert_difference('Trade.count', 3) do
      post trades_url, params: trades, as: :json
    end
  end

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

  test "should rollback batch trade if a trade failed to save" do
    trades = []
    3.times do
      trades << generate_trade({ :account_address => @trade.account_address, :order_hash => @orders[0].order_hash, :amount => @trade.amount.to_i / 3 })
    end
    trades.last[:signature] = 'INVALID'

    assert_no_difference('Trade.count') do
      post trades_url, params: trades, as: :json
    end
  end

  test "trade_balances should initialize balances if not exist" do
    # create a new maker and taker accounts, top up, create maker's order and taker's trade
    fee_address = ENV['FEE_COLLECTOR_ADDRESS'].without_checksum
    maker_address = addresses[7]
    taker_address = addresses[8]
    give_token_address = "0x21921361bab476be44c0655256a2f4281bfcf07d"
    take_token_address = "0x0000000000000000000000000000000000000000"
    give_amount = "100000000000000000000"
    take_amount = "100000000000000000000"
    Balance.find_or_create_by({ account_address: maker_address, token_address: give_token_address })
    Balance.find_or_create_by({ account_address: taker_address, token_address: take_token_address })
    deposits = batch_deposit([
      { :account_address => maker_address, :token_address => give_token_address, :amount => give_amount },
      { :account_address => taker_address, :token_address => take_token_address, :amount => take_amount }
    ])
    orders = batch_order([
      { :account_address => maker_address, :give_token_address => give_token_address, :give_amount => give_amount, :take_token_address => take_token_address, :take_amount => take_amount }
    ])
    trade = generate_trade({ :account_address => taker_address, :order_hash => orders[0].order_hash, :amount => give_amount })
    # delete fee give and take balances
    Balance.find_by({ :account_address => fee_address, :token_address => give_token_address }).destroy
    Balance.find_by({ :account_address => fee_address, :token_address => take_token_address }).destroy
    # fee give/take, maker take, taker give don't exist before the trade
    fee_give_balance = Balance.find_by({ :account_address => fee_address, :token_address => give_token_address })
    fee_take_balance = Balance.find_by({ :account_address => fee_address, :token_address => take_token_address })
    maker_take_balance = Balance.find_by({ :account_address => maker_address, :token_address => take_token_address })
    taker_give_balance = Balance.find_by({ :account_address => taker_address, :token_address => give_token_address })
    assert_nil fee_give_balance
    assert_nil fee_take_balance
    assert_nil maker_take_balance
    assert_nil taker_give_balance
    # fee give/take, maker take, taker give are created after the trade
    assert_difference("Balance.count", 4) do
      post trades_url, params: [trade], as: :json
      fee_give_balance = Balance.find_by({ :account_address => fee_address, :token_address => give_token_address })
      fee_take_balance = Balance.find_by({ :account_address => fee_address, :token_address => take_token_address })
      maker_take_balance = Balance.find_by({ :account_address => maker_address, :token_address => take_token_address })
      taker_give_balance = Balance.find_by({ :account_address => taker_address, :token_address => give_token_address })
      assert_not_nil fee_give_balance
      assert_not_nil fee_take_balance
      assert_not_nil maker_take_balance
      assert_not_nil taker_give_balance
    end
  end

  test "should close sell order after trade if remaining volume doesnt meet taker minimum" do
    order = @orders[0]
    trade = generate_trade({ :account_address => @trade.account_address, :order_hash => order.order_hash, :amount => "91".to_wei })

    assert_equal order.reload.status, 'open'

    assert_difference('Trade.count') do
      post trades_url, params: [trade], as: :json
      assert_response 201
      assert_equal order.reload.status, 'closed'
    end
  end

  test "should close buy order after trade if remaining volume doesnt meet taker minimum" do
    deposits = batch_deposit([
      { :account_address => @order.account_address, :token_address => @order.give_token_address, :amount => "1".to_wei },
      { :account_address => @order.account_address, :token_address => @order.take_token_address, :amount => "1".to_wei }
    ])
    orders = batch_order([
      { :account_address => @order.account_address, :give_token_address => @order.take_token_address, :give_amount => "1".to_wei, :take_token_address => @order.give_token_address, :take_amount => "1".to_wei }
    ])
    trade = generate_trade({ :account_address => @order.account_address, :order_hash => orders[0].order_hash, :amount => "0.96".to_wei })

    assert_not orders[0].is_sell
    assert_equal orders[0].reload.status, 'open'

    assert_difference('Trade.count') do
      post trades_url, params: [trade], as: :json
      assert_response 201
      assert_equal orders[0].reload.status, 'closed'
    end
  end

  test "should be consistent with on-chain balances" do
    give_token = tokens(:one)
    take_token = tokens(:four)
    give_amount = 195738239776775570
    take_amount = 59744193591648150
    fill_amount = 163813609331349736

    # syncing maker's give balance
    maker_give_balance = balances(:four)
    withdraws = batch_withdraw([
      { :account_address => maker_give_balance.account_address, :token_address => maker_give_balance.token_address, :amount => maker_give_balance.balance }
    ])
    deposits = batch_deposit([
      { :account_address => maker_give_balance.account_address, :token_address => maker_give_balance.token_address, :amount => maker_give_balance.onchain_balance }
    ])

    # maker's take balance doesn't need syncing because they are both 0
    maker_take_balance = balances(:twenty_one)

    # syncing taker's give balance
    taker_give_balance = balances(:two)
    batch_withdraw([
      { :account_address => taker_give_balance.account_address, :token_address => taker_give_balance.token_address, :amount => taker_give_balance.balance }
    ])
    batch_deposit([
      { :account_address => taker_give_balance.account_address, :token_address => taker_give_balance.token_address, :amount => taker_give_balance.onchain_balance }
    ])

    # syncing taker's take balance
    taker_take_balance = balances(:twenty)
    batch_deposit([
      { :account_address => taker_take_balance.account_address, :token_address => taker_take_balance.token_address, :amount => taker_take_balance.onchain_balance }
    ])

    # syncing make fee collector's balance
    fee_give_balance = balances(:fee_one)
    fee_give_balance.debit(fee_give_balance.balance)
    fee_give_balance.credit(fee_give_balance.onchain_balance)

    # syncing take fee collector's balance
    fee_take_balance = balances(:fee_four)
    fee_take_balance.debit(fee_take_balance.balance)
    fee_take_balance.credit(fee_take_balance.onchain_balance)

    # before trade assertions
    assert_equal maker_give_balance.reload.balance, maker_give_balance.onchain_balance
    assert_equal maker_take_balance.reload.balance, maker_take_balance.onchain_balance
    assert_equal taker_give_balance.reload.balance, taker_give_balance.onchain_balance
    assert_equal taker_take_balance.reload.balance, taker_take_balance.onchain_balance
    assert_equal fee_give_balance.reload.balance, fee_give_balance.onchain_balance
    assert_equal fee_take_balance.reload.balance, fee_take_balance.onchain_balance

    # trade
    sync_nonce
    order = Order.create(generate_order({ :account_address => maker_give_balance.account_address, :give_token_address => maker_give_balance.token_address, :give_amount => give_amount, :take_token_address => taker_take_balance.token_address, :take_amount => take_amount }))
    trade = Trade.create(generate_trade({ :account_address => taker_take_balance.account_address, :order_hash => order.order_hash, :amount => fill_amount }))
    begin
      BroadcastTransactionJob.perform_now(trade.tx)
    rescue
      byebug
    end

    # after trade assertions
    assert_equal maker_give_balance.reload.balance, maker_give_balance.onchain_balance
    assert_equal maker_take_balance.reload.balance, maker_take_balance.onchain_balance
    assert_equal taker_give_balance.reload.balance, taker_give_balance.onchain_balance
    assert_equal taker_take_balance.reload.balance, taker_take_balance.onchain_balance
    assert_equal fee_give_balance.reload.balance, fee_give_balance.onchain_balance
    assert_equal fee_take_balance.reload.balance, fee_take_balance.onchain_balance
  end
end
