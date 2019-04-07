require 'test_helper'

class TransactionTest < ActiveSupport::TestCase
  setup do
    sync_nonce
    @client = Ethereum::Singleton.instance
    @exchange = Contract::Exchange.singleton.instance
    @transaction = transactions(:one)
    @balance = balances(:eighteen)
  end

  test "has transactable" do
    assert_not_nil @transaction.transactable
  end

  test "should rebroadcast expired transactions" do
    withdraw1, withdraw2 = batch_withdraw([
      { :account_address => accounts[0], :token_address => '0x0000000000000000000000000000000000000000', :amount => 20000000000000000 },
      { :account_address => accounts[0], :token_address => '0x0000000000000000000000000000000000000000', :amount => 30000000000000000 }
    ])
    withdraw1.tx.update({ :created_at => 15.minutes.ago })
    withdraw2.tx.update({ :created_at => 15.minutes.ago })
    expired_transaction1 = withdraw1.tx
    expired_transaction2 = withdraw2.tx

    assert_changes 'expired_transaction1.transaction_hash and expired_transaction2.transaction_hash' do
      Transaction.rebroadcast_expired_transactions
      expired_transaction1.reload
      expired_transaction2.reload
    end
  end

  test "should mark transaction as 'replaced' if nonce has been taken" do
    withdraw = batch_withdraw([
      { :account_address => accounts[0], :token_address => '0x0000000000000000000000000000000000000000', :amount => 20000000000000000 }
    ]).first
    withdraw.tx.update({ :nonce => 0 })

    Transaction.confirm_mined_transactions
    withdraw.tx.reload
    assert_equal(withdraw.tx.status, 'replaced')
  end

  test "should confirm successful transactions" do
    withdraw = batch_withdraw([
      { :account_address => accounts[0], :token_address => '0x0000000000000000000000000000000000000000', :amount => 20000000000000000 }
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
      { :account_address => accounts[5], :token_address => '0x0000000000000000000000000000000000000000', :amount => '1'.to_wei }
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
      assert_equal @balance.balance.to_ether, '0.3' # accounts[5] has 0.3 ether pre-deposited in /chaindata
    end
  end

  test "should detect and remove fake coins upon an unsuccessful order" do
    taker_balance = Account.find_by({ :address => accounts[0] }).balance('0x75d417ab3031d592a781e666ee7bfc3381ad33d5')
    before_taker_balance = taker_balance.balance
    order = batch_order([
      { :account_address => accounts[5], :give_token_address => '0x0000000000000000000000000000000000000000', :give_amount => '1'.to_wei, :take_token_address => '0x75d417ab3031d592a781e666ee7bfc3381ad33d5', :take_amount => '1'.to_wei }
    ]).first
    trade = batch_trade([
      { :account_address => accounts[0], :order_hash => order.order_hash, :amount => '1'.to_wei }
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
      assert_equal @balance.balance.to_ether, '0.3'
      after_taker_balance = taker_balance.reload.balance
      assert_equal before_taker_balance, after_taker_balance
    end
  end

  test "should detect and remove fake coins upon an unsuccessful trade" do
    maker_balance = Account.find_by({ :address => accounts[0] }).balance('0x75d417ab3031d592a781e666ee7bfc3381ad33d5')
    before_maker_balance = maker_balance.balance
    order = batch_order([
      { :account_address => accounts[0], :give_token_address => '0x75d417ab3031d592a781e666ee7bfc3381ad33d5', :give_amount => '1'.to_wei, :take_token_address => '0x0000000000000000000000000000000000000000', :take_amount => '1'.to_wei }
    ]).first
    trade = batch_trade([
      { :account_address => accounts[5], :order_hash => order.order_hash, :amount => '1'.to_wei }
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
      assert_equal @balance.balance.to_ether, '0.3'
      after_maker_balance = maker_balance.reload.balance
      assert_equal before_maker_balance, after_maker_balance
    end
  end
end
