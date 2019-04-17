require 'test_helper'

class TransactionTest < ActiveSupport::TestCase
  setup do
    sync_nonce
    @client = Ethereum::Singleton.instance
    @exchange = Contract::Exchange.singleton.instance
    @transaction = transactions(:one)
    @balance = balances(:eighteen)
  end

  # test "has transactable" do
  #   assert_not_nil @transaction.transactable
  # end

  # test "should rebroadcast expired transactions" do
  #   withdraw1, withdraw2 = batch_withdraw([
  #     { :account_address => accounts[0], :token_address => '0x0000000000000000000000000000000000000000', :amount => 20000000000000000 },
  #     { :account_address => accounts[0], :token_address => '0x0000000000000000000000000000000000000000', :amount => 30000000000000000 }
  #   ])
  #   withdraw1.tx.update({ :created_at => 15.minutes.ago })
  #   withdraw2.tx.update({ :created_at => 15.minutes.ago })
  #   expired_transaction1 = withdraw1.tx
  #   expired_transaction2 = withdraw2.tx

  #   assert_changes 'expired_transaction1.transaction_hash and expired_transaction2.transaction_hash' do
  #     Transaction.broadcast_expired_transactions
  #     expired_transaction1.reload
  #     expired_transaction2.reload
  #   end
  # end

  # test "should mark transaction as 'replaced' if nonce has been taken" do
  #   withdraw = batch_withdraw([
  #     { :account_address => accounts[0], :token_address => '0x0000000000000000000000000000000000000000', :amount => 20000000000000000 }
  #   ]).first
  #   withdraw.tx.update({ :nonce => 0 })

  #   Transaction.confirm_mined_transactions
  #   withdraw.tx.reload
  #   assert_equal(withdraw.tx.status, 'replaced')
  # end

  # test "should confirm successful transactions" do
  #   withdraw = batch_withdraw([
  #     { :account_address => accounts[0], :token_address => '0x0000000000000000000000000000000000000000', :amount => 20000000000000000 }
  #   ]).first
  #   transaction = withdraw.tx
  #   BroadcastTransactionJob.perform_now(transaction)

  #   assert_changes 'transaction.block_hash and transaction.block_number and transaction.gas' do
  #     Transaction.confirm_mined_transactions
  #     transaction.reload
  #     assert_equal transaction.status, 'confirmed'
  #   end
  # end

  # test "should detect and remove fake coins upon an unsuccessful withdraw" do
  #   withdraw = batch_withdraw([
  #     { :account_address => accounts[5], :token_address => '0x0000000000000000000000000000000000000000', :amount => '1'.to_wei }
  #   ]).first
  #   transaction = withdraw.tx

  #   # ganache raises an error upon VM exceptions instead of returning the transaction hash
  #   # so we have to ignore the error and update transaction_hash manually
  #   begin
  #     BroadcastTransactionJob.perform_now(transaction)
  #   rescue
  #     transaction_hash = @client.eth_get_block_by_number('latest', false)['result']['transactions'].first
  #     transaction.update!({ :transaction_hash => transaction_hash, :status => 'unconfirmed' })
  #   end

  #   assert_changes 'transaction.block_hash and transaction.block_number and transaction.gas' do
  #     Transaction.confirm_mined_transactions
  #     transaction.reload
  #     @balance.reload
  #     assert_equal transaction.status, 'failed'
  #     assert_equal @balance.balance.to_ether, '0.0'
  #   end
  # end

  # test "should detect and remove fake coins upon an unsuccessful order" do
  #   taker_balance = Account.find_by({ :address => accounts[0] }).balance('0x75d417ab3031d592a781e666ee7bfc3381ad33d5')
  #   before_taker_balance = taker_balance.balance
  #   order = batch_order([
  #     { :account_address => accounts[5], :give_token_address => '0x0000000000000000000000000000000000000000', :give_amount => '1'.to_wei, :take_token_address => '0x75d417ab3031d592a781e666ee7bfc3381ad33d5', :take_amount => '1'.to_wei }
  #   ]).first
  #   trade = batch_trade([
  #     { :account_address => accounts[0], :order_hash => order.order_hash, :amount => '1'.to_wei }
  #   ]).first
  #   transaction = trade.tx

  #   begin
  #     BroadcastTransactionJob.perform_now(transaction)
  #   rescue
  #     transaction_hash = @client.eth_get_block_by_number('latest', false)['result']['transactions'].first
  #     transaction.update!({ :transaction_hash => transaction_hash, :status => 'unconfirmed' })
  #   end

  #   assert_changes 'transaction.block_hash and transaction.block_number and transaction.gas' do
  #     Transaction.confirm_mined_transactions
  #     transaction.reload
  #     @balance.reload
  #     assert_equal transaction.status, 'failed'
  #     assert_equal @balance.balance.to_ether, '0.0'
  #     after_taker_balance = taker_balance.reload.balance
  #     assert_equal before_taker_balance, after_taker_balance
  #   end
  # end

  # test "should detect and remove fake coins upon an unsuccessful trade" do
  #   maker_balance = Account.find_by({ :address => accounts[0] }).balance('0x75d417ab3031d592a781e666ee7bfc3381ad33d5')
  #   before_maker_balance = maker_balance.balance
  #   order = batch_order([
  #     { :account_address => accounts[0], :give_token_address => '0x75d417ab3031d592a781e666ee7bfc3381ad33d5', :give_amount => '1'.to_wei, :take_token_address => '0x0000000000000000000000000000000000000000', :take_amount => '1'.to_wei }
  #   ]).first
  #   trade = batch_trade([
  #     { :account_address => accounts[5], :order_hash => order.order_hash, :amount => '1'.to_wei }
  #   ]).first
  #   transaction = trade.tx

  #   begin
  #     BroadcastTransactionJob.perform_now(transaction)
  #   rescue
  #     transaction_hash = @client.eth_get_block_by_number('latest', false)['result']['transactions'].first
  #     transaction.update!({ :transaction_hash => transaction_hash, :status => 'unconfirmed' })
  #   end

  #   assert_changes 'transaction.block_hash and transaction.block_number and transaction.gas' do
  #     Transaction.confirm_mined_transactions
  #     transaction.reload
  #     @balance.reload
  #     assert_equal transaction.status, 'failed'
  #     assert_equal @balance.balance.to_ether, '0.0'
  #     after_maker_balance = maker_balance.reload.balance
  #     assert_equal before_maker_balance, after_maker_balance
  #   end
  # end

  test "should regenerate and rebroadcast replaced transactions" do
    # A trades with B
    # transaction X overrides the trade's nonce

    # A and B's trade is broadcasted, failed and marked as 'replaced'
    # A's withdraw is broadcasted, succeeded and marked as 'confirmed'
    # B's withdraw is broadcasted, failed and marked as 'failed'

    # Transaction.broadcast_expired_transactions
    # A's withdraw is unaffected
    # A and B's trade is regenerated, broadcasted and confirmed
    # B's withdraw is regenerated, broadcasted and confirmed

    order = batch_order([
      { :account_address => accounts[1], :give_token_address => '0x0000000000000000000000000000000000000000', :give_amount => '1'.to_wei, :take_token_address => '0x75d417ab3031d592a781e666ee7bfc3381ad33d5', :take_amount => '1'.to_wei }
    ]).first
    trade = batch_trade([
      { :account_address => accounts[0], :order_hash => order.order_hash, :amount => '1'.to_wei }
    ]).first
    withdraw1, withdraw2, replacer = batch_withdraw([
      { :account_address => accounts[0], :token_address => '0x0000000000000000000000000000000000000000', :amount => 20000000000000000 },
      { :account_address => accounts[1], :token_address => '0x75d417ab3031d592a781e666ee7bfc3381ad33d5', :amount => 20000000000000000 },
      { :account_address => accounts[0], :token_address => '0x0000000000000000000000000000000000000000', :amount => 20000000000000000 }
    ])
    replacer.tx.update({ :nonce => trade.tx.nonce })
    BroadcastTransactionJob.perform_now(replacer.tx)
    assert_equal(ENV['READ_ONLY'], 'false')

    Transaction.broadcast_pending_transactions
    Transaction.confirm_mined_transactions
    assert_equal(trade.reload.tx.status, 'replaced')
    assert_equal(withdraw1.reload.tx.status, 'confirmed')
    assert_equal(withdraw2.reload.tx.status, 'failed')
    assert_equal(replacer.reload.tx.status, 'confirmed')
    assert_equal(ENV['READ_ONLY'], 'true')

    assert_changes 'trade.tx.nonce and withdraw1.tx.nonce and withdraw2.tx.nonce' do
      Transaction.broadcast_expired_transactions
      # Transaction.confirm_mined_transactions
      trade.reload
      withdraw1.reload
      withdraw2.reload
    end

    p trade.reload.tx.status, withdraw1.reload.tx.status, withdraw2.reload.tx.status, replacer.reload.tx.status
  end

  # test "should not regenerate replaced transactions if there are still unconfirmed transactions" do
  #   # set up an unconfirmed transaction in db
  #   # transaction X is replaced
  #   # Transaction.broadcast_expired_transactions
  #   # an unconfirmed transaction is present, trasaction X is unaffected
  # end
end
