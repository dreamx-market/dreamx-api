require 'test_helper'

class AccountTest < ActiveSupport::TestCase
  test "initialize_if_not_exist should not reset existing balances to 0" do
    existing_balance = Balance.find_by({ :account_address => "0xfa46ed8f8d3f15e7d820e7246233bbd9450903e3", :token_address => "0x21921361bab476be44c0655256a2f4281bfcf07d" })
    batch_deposit([
      { :account_address => existing_balance.account_address, :token_address => existing_balance.token_address, :amount => 10 }
    ])
    existing_balance.reload
    assert_no_changes("existing_balance.balance") do
      Account.initialize_if_not_exist(existing_balance.account_address, existing_balance.token_address)
      existing_balance.reload
    end
  end
end
