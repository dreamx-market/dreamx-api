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
