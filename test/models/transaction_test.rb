require 'test_helper'

class TransactionTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    sync_nonce
    @client = Ethereum::Singleton.instance
    @exchange = Contract::Exchange.singleton.instance
    @transaction = transactions(:one)
    @balance = balances(:eighteen)
  end

  teardown do
    Config.set('read_only', 'false')
  end

  test "has transactable" do
    assert_not_nil @transaction.transactable
  end

  test "should rebroadcast expired transactions" do
    withdraw1, withdraw2 = batch_withdraw([
      { :account_address => addresses[0], :token_address => '0x0000000000000000000000000000000000000000', :amount => 20000000000000000 },
      { :account_address => addresses[0], :token_address => '0x0000000000000000000000000000000000000000', :amount => 30000000000000000 }
    ])
    expired_transaction1 = withdraw1.tx
    expired_transaction2 = withdraw2.tx

    assert_changes 'expired_transaction1.transaction_hash and expired_transaction2.transaction_hash' do
      perform_enqueued_jobs do
        Transaction.broadcast_expired_transactions
      end
      expired_transaction1.reload
      expired_transaction2.reload
    end
  end

  test "should mark transaction as 'replaced' if transaction hash is nil or nonce has been taken" do
    withdraw = batch_withdraw([
      { :account_address => addresses[0], :token_address => '0x0000000000000000000000000000000000000000', :amount => 20000000000000000 }
    ]).first
    withdraw.tx.update({ :nonce => 0 })

    assert_difference("TransactionLog.count") do
      Transaction.confirm_mined_transactions
      withdraw.tx.reload
      assert_equal(withdraw.tx.status, 'replaced')
      assert_equal(Config.get('read_only'), 'true')
    end
  end

  test "should mark transaction as 'replaced' if transaction hash can't be found and nonce has been taken" do
    fake_hash = "0xdbdc317030649528999952670dbf5460693067a33ad805268d1b21e8aa558609"
    withdraw = batch_withdraw([
      { :account_address => addresses[0], :token_address => '0x0000000000000000000000000000000000000000', :amount => 20000000000000000 }
    ]).first
    withdraw.tx.update({ :nonce => 0, :transaction_hash => fake_hash })

    Transaction.confirm_mined_transactions
    withdraw.tx.reload
    assert_equal(withdraw.tx.status, 'replaced')
    assert_equal(Config.get('read_only'), 'true')
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
    # B's withdraw is not regenerated or rebroadcasted because rebroadcasting failed transactions means rebroadcasting not only the transactions that failed because a transaction that it depends on was replaced but also the transactions that failed because they were genuinely invalid, e.g. transactions of withdrawals with fake coins or trades that have been traded

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
    assert_equal(Config.get('read_only'), 'false')

    perform_enqueued_jobs do
      Transaction.broadcast_pending_transactions
    end
    Transaction.confirm_mined_transactions

    assert_equal(trade.reload.tx.status, 'replaced')
    assert_equal(withdraw1.reload.tx.status, 'confirmed')
    assert_equal(withdraw2.reload.tx.status, 'failed')
    assert_equal(replacer.reload.tx.status, 'confirmed')
    assert_equal(Config.get('read_only'), 'true')

    assert_no_changes 'replacer.tx.nonce' do
    assert_no_changes 'withdraw1.tx.nonce' do
    assert_changes 'trade.tx.nonce' do
    assert_no_changes 'withdraw2.tx.nonce' do
      # manually expire txs so they can be broadcasted, in production, they will likely be expired
      # already by the time they are re-generated
      Transaction.replaced.each do |transaction|
      end

      perform_enqueued_jobs do
        Transaction.broadcast_expired_transactions
      end
      Transaction.confirm_mined_transactions
      assert_equal(trade.reload.tx.status, 'confirmed')
      assert_equal(withdraw2.reload.tx.status, 'failed')
      assert_equal(Config.get('read_only'), 'false')
    end
    end
    end
    end
  end

  test "should not regenerate replaced transactions if there are still unconfirmed transactions" do
    withdraw1, replacer = batch_withdraw([
      { :account_address => addresses[0], :token_address => '0x0000000000000000000000000000000000000000', :amount => 20000000000000000 },
      { :account_address => addresses[0], :token_address => '0x0000000000000000000000000000000000000000', :amount => 20000000000000000 }
    ])
    replacer.tx.update({ :nonce => withdraw1.tx.nonce })
    BroadcastTransactionJob.perform_now(replacer.tx)
    assert_equal(Config.get('read_only'), 'false')

    Transaction.broadcast_pending_transactions
    Transaction.confirm_mined_transactions

    assert_equal(withdraw1.reload.tx.status, 'replaced')
    assert_equal(replacer.reload.tx.status, 'confirmed')
    assert_equal(Config.get('read_only'), 'true')

    assert_no_changes 'withdraw1.tx.nonce' do
      # create an unconfirmed transaction
      withdraw2 = batch_withdraw([
        { :account_address => addresses[0], :token_address => '0x0000000000000000000000000000000000000000', :amount => 20000000000000000 }
      ])

      # manually expire txs so they can be broadcasted, in production, they will likely be expired
      # already by the time they are re-generated
      Transaction.broadcast_expired_transactions
      assert_equal(withdraw1.reload.tx.status, 'replaced')
      assert_equal(Config.get('read_only'), 'true')
    end
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

  test "regenerated transactions should have their hashes reset to nil and their status reset to pending" do
    # broadcast a transaction, update its status and hash
    withdraw = batch_withdraw([
      { :account_address => addresses[0], :token_address => '0x0000000000000000000000000000000000000000', :amount => 20000000000000000 }
    ])[0]
    transaction = withdraw.tx
    BroadcastTransactionJob.perform_now(transaction)
    transaction.reload
    assert_not_nil transaction.transaction_hash
    assert transaction.status, "unconfirmed"

    # manually mark it as replaced
    transaction.update({ :status => 'replaced' })

    # hash and status should be reset after regeneration
    Transaction.regenerate_replaced_transactions
    transaction.reload
    assert_nil transaction.transaction_hash
    assert transaction.status, "pending"
  end
end
