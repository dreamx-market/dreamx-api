require 'test_helper'

class TransactionTest < ActiveSupport::TestCase
  setup do
    sync_nonce
    @client = Ethereum::Singleton.instance
    @exchange = Contract::Exchange.singleton.instance
    @transaction = transactions(:one)
    @balance = balances(:eighteen)
  end

  teardown do
    ENV['READ_ONLY'] = 'false'
  end

  test "has transactable" do
    assert_not_nil @transaction.transactable
  end

  test "should rebroadcast expired transactions" do
    withdraw1, withdraw2 = batch_withdraw([
      { :account_address => addresses[0], :token_address => '0x0000000000000000000000000000000000000000', :amount => 20000000000000000 },
      { :account_address => addresses[0], :token_address => '0x0000000000000000000000000000000000000000', :amount => 30000000000000000 }
    ])
    withdraw1.tx.update({ :created_at => 15.minutes.ago })
    withdraw2.tx.update({ :created_at => 15.minutes.ago })
    expired_transaction1 = withdraw1.tx
    expired_transaction2 = withdraw2.tx

    assert_changes 'expired_transaction1.transaction_hash and expired_transaction2.transaction_hash' do
      Transaction.broadcast_expired_transactions
      expired_transaction1.reload
      expired_transaction2.reload
    end
  end

  test "should mark transaction as 'replaced' if nonce has been taken" do
    withdraw = batch_withdraw([
      { :account_address => addresses[0], :token_address => '0x0000000000000000000000000000000000000000', :amount => 20000000000000000 }
    ]).first
    withdraw.tx.update({ :nonce => 0 })

    Transaction.confirm_mined_transactions
    withdraw.tx.reload
    assert_equal(withdraw.tx.status, 'replaced')
    assert_equal(ENV['READ_ONLY'], 'true')
  end

  test "should confirm successful transactions" do
    withdraw = batch_withdraw([
      { :account_address => addresses[0], :token_address => '0x0000000000000000000000000000000000000000', :amount => 20000000000000000 }
    ]).first
    transaction = withdraw.tx
    BroadcastTransactionJob.perform_now(transaction)

    assert_changes 'transaction.block_hash and transaction.block_number and transaction.gas' do
      Transaction.confirm_mined_transactions
      transaction.reload
      assert_equal transaction.status, 'confirmed'
    end
  end

  test "should detect and remove fake coins upon an unsuccessful withdraw" do
    withdraw = batch_withdraw([
      { :account_address => addresses[5], :token_address => '0x0000000000000000000000000000000000000000', :amount => '1'.to_wei }
    ]).first
    transaction = withdraw.tx

    # ganache raises an error upon VM exceptions instead of returning the transaction hash
    # so we have to ignore the error and update transaction_hash manually
    begin
      BroadcastTransactionJob.perform_now(transaction)
    rescue
      transaction_hash = @client.eth_get_block_by_number('latest', false)['result']['transactions'].first
      transaction.update!({ :transaction_hash => transaction_hash, :status => 'unconfirmed' })
    end

    assert_changes 'transaction.block_hash and transaction.block_number and transaction.gas' do
      Transaction.confirm_mined_transactions
      transaction.reload
      @balance.reload
      assert_equal transaction.status, 'failed'
      assert_equal @balance.balance.to_ether, '0.0'
    end
  end

  test "should detect and remove fake coins upon an unsuccessful order" do
    taker_balance = Account.find_by({ :address => addresses[0] }).balance('0x75d417ab3031d592a781e666ee7bfc3381ad33d5')
    before_taker_balance = taker_balance.balance
    order = batch_order([
      { :account_address => addresses[5], :give_token_address => '0x0000000000000000000000000000000000000000', :give_amount => '1'.to_wei, :take_token_address => '0x75d417ab3031d592a781e666ee7bfc3381ad33d5', :take_amount => '1'.to_wei }
    ]).first
    trade = batch_trade([
      { :account_address => addresses[0], :order_hash => order.order_hash, :amount => '1'.to_wei }
    ]).first
    transaction = trade.tx

    begin
      BroadcastTransactionJob.perform_now(transaction)
    rescue
      transaction_hash = @client.eth_get_block_by_number('latest', false)['result']['transactions'].first
      transaction.update!({ :transaction_hash => transaction_hash, :status => 'unconfirmed' })
    end

    assert_changes 'transaction.block_hash and transaction.block_number and transaction.gas' do
      Transaction.confirm_mined_transactions
      transaction.reload
      @balance.reload
      assert_equal transaction.status, 'failed'
      assert_equal @balance.balance.to_ether, '0.0'
      after_taker_balance = taker_balance.reload.balance
      assert_equal before_taker_balance, after_taker_balance
    end
  end

  test "should detect and remove fake coins upon an unsuccessful trade" do
    maker_balance = Account.find_by({ :address => addresses[0] }).balance('0x75d417ab3031d592a781e666ee7bfc3381ad33d5')
    before_maker_balance = maker_balance.balance
    order = batch_order([
      { :account_address => addresses[0], :give_token_address => '0x75d417ab3031d592a781e666ee7bfc3381ad33d5', :give_amount => '1'.to_wei, :take_token_address => '0x0000000000000000000000000000000000000000', :take_amount => '1'.to_wei }
    ]).first
    trade = batch_trade([
      { :account_address => addresses[5], :order_hash => order.order_hash, :amount => '1'.to_wei }
    ]).first
    transaction = trade.tx

    begin
      BroadcastTransactionJob.perform_now(transaction)
    rescue
      transaction_hash = @client.eth_get_block_by_number('latest', false)['result']['transactions'].first
      transaction.update!({ :transaction_hash => transaction_hash, :status => 'unconfirmed' })
    end

    assert_changes 'transaction.block_hash and transaction.block_number and transaction.gas' do
      Transaction.confirm_mined_transactions
      transaction.reload
      @balance.reload
      assert_equal transaction.status, 'failed'
      assert_equal @balance.balance.to_ether, '0.0'
      after_maker_balance = maker_balance.reload.balance
      assert_equal before_maker_balance, after_maker_balance
    end
  end

  test "should regenerate and rebroadcast replaced transactions" do
    # A trades with B
    # transaction X overrides the trade's nonce

    # A and B's trade is broadcasted, failed and marked as 'replaced'
    # A's withdraw is broadcasted, succeeded and marked as 'confirmed' because he already has the funds
    # B's withdraw is broadcasted, failed and marked as 'failed' because he is dependent on the success of the trade

    # Transaction.broadcast_expired_transactions
    # A's withdraw is unaffected
    # A and B's trade is regenerated, broadcasted and confirmed
    # B's withdraw is regenerated, broadcasted and confirmed

    order = batch_order([
      { :account_address => addresses[1], :give_token_address => '0x0000000000000000000000000000000000000000', :give_amount => '1'.to_wei, :take_token_address => '0x75d417ab3031d592a781e666ee7bfc3381ad33d5', :take_amount => '1'.to_wei }
    ]).first
    trade = batch_trade([
      { :account_address => addresses[0], :order_hash => order.order_hash, :amount => '1'.to_wei }
    ]).first
    withdraw1, withdraw2, replacer = batch_withdraw([
      { :account_address => addresses[0], :token_address => '0x0000000000000000000000000000000000000000', :amount => 20000000000000000 },
      { :account_address => addresses[1], :token_address => '0x75d417ab3031d592a781e666ee7bfc3381ad33d5', :amount => 999000000000000000 },
      { :account_address => addresses[0], :token_address => '0x0000000000000000000000000000000000000000', :amount => 20000000000000000 }
    ])
    replacer.tx.update({ :nonce => trade.tx.nonce })
    BroadcastTransactionJob.perform_now(replacer.tx)
    assert_equal(ENV['READ_ONLY'], 'false')

    Transaction.broadcast_pending_transactions
    Transaction.confirm_mined_transactions

    if (trade.reload.tx.status != 'replaced') or (withdraw2.reload.tx.status != 'failed')
      debugger
    end

    assert_equal(trade.reload.tx.status, 'replaced')
    assert_equal(withdraw1.reload.tx.status, 'confirmed')
    assert_equal(withdraw2.reload.tx.status, 'failed')
    assert_equal(replacer.reload.tx.status, 'confirmed')
    assert_equal(ENV['READ_ONLY'], 'true')

    assert_no_changes 'replacer.tx.nonce' do
    assert_no_changes 'withdraw1.tx.nonce' do
    assert_changes 'trade.tx.nonce' do
    assert_changes 'withdraw2.tx.nonce' do
      # manually expire txs so they can be broadcasted, in production, they will likely be expired
      # already by the time they are re-generated
      Transaction.replaced.each do |transaction|
        transaction.update({ :created_at => 10.minutes.ago })
      end

      Transaction.broadcast_expired_transactions
      Transaction.confirm_mined_transactions
      assert_equal(trade.reload.tx.status, 'confirmed')
      assert_equal(withdraw2.reload.tx.status, 'confirmed')
      assert_equal(ENV['READ_ONLY'], 'false')
    end
    end
    end
    end
  end

  test "should not regenerate replaced transactions if there are still unconfirmed transactions" do
    # set up an unconfirmed transaction in db
    # transaction X is replaced
    # Transaction.broadcast_expired_transactions
    # an unconfirmed transaction is present, trasaction X is unaffected
  end

  test "should mark failed transactions as out_of_gas if gas used is equal to gas limit" do
    ENV['GAS_LIMIT'] = '30000'

    withdraw = batch_withdraw([
      { :account_address => addresses[0], :token_address => '0x0000000000000000000000000000000000000000', :amount => 20000000000000000 }
    ]).first

    # ganache raises an error upon VM exceptions instead of returning the transaction hash
    # so we have to ignore the error and update transaction_hash manually
    begin
      BroadcastTransactionJob.perform_now(withdraw.tx)
    rescue
      transaction_hash = @client.eth_get_block_by_number('latest', false)['result']['transactions'].first
      withdraw.tx.update!({ :transaction_hash => transaction_hash, :status => 'unconfirmed', :gas_limit => withdraw.tx.raw.gas_limit, :gas_price => withdraw.tx.raw.gas_price })
    end

    Transaction.confirm_mined_transactions
    assert_equal(withdraw.reload.tx.status, "out_of_gas")

    ENV['GAS_LIMIT'] = '2000000'
  end
end
