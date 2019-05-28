require 'test_helper'
 
class AccountTransfersTest < ActionCable::TestCase
  include ActiveJob::TestHelper

  setup do
    @deposit = deposits(:one)
    @withdraw = withdraws(:one)
  end
  
  test "broadcast a message when a new deposit is created" do
    new_deposit = Deposit.new({ :account_address => @deposit.account_address, :token_address => @deposit.token_address, :amount => @deposit.amount })

    assert_broadcasts("account_transfers:#{new_deposit.account_address}", 1) do
      perform_enqueued_jobs do
        new_deposit.save
      end
    end
  end

  test "broadcast a message when a new withdrawal is created" do
    deposit_data = [
      { :account_address => @withdraw.account_address, :token_address => @withdraw.token_address, :amount => @withdraw.amount }
    ]
    batch_deposit(deposit_data)

    new_withdraw = Withdraw.new(generate_withdraw(@withdraw))

    assert_broadcasts("account_transfers:#{new_withdraw.account_address}", 1) do
      perform_enqueued_jobs do
        new_withdraw.save
      end
    end
  end
end