require 'test_helper'

class TransactionTest < ActiveSupport::TestCase
  setup do
    sync_nonce
    @transaction = transactions(:one)
  end

  test "has transactable" do
    assert_not_nil @transaction.transactable
  end

  test "should rebroadcast expired transactions" do
    withdraw1, withdraw2 = batch_withdraw([
      { :account_address => accounts[0], :token_address => '0x0000000000000000000000000000000000000000', :amount => 20000000000000000, :nonce => (Time.now.to_i * 1000).to_s },
      { :account_address => accounts[0], :token_address => '0x0000000000000000000000000000000000000000', :amount => 30000000000000000, :nonce => (Time.now.to_i * 1000 + 1).to_s }
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
end
