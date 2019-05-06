require 'test_helper'

class ChartDatumTest < ActiveSupport::TestCase
  setup do
    @deposits = batch_deposit([
      { :account_address => "0x76446f63c6b7756257b9c7d56ce7dde29836c203", :token_address => "0x0000000000000000000000000000000000000000", :amount => "100".to_wei },
      { :account_address => "0x76446f63c6b7756257b9c7d56ce7dde29836c203", :token_address => "0x21921361bab476be44c0655256a2f4281bfcf07d", :amount => "100".to_wei }
    ])
    @orders = batch_order([
      { :account_address => "0x76446f63c6b7756257b9c7d56ce7dde29836c203", :give_token_address => "0x0000000000000000000000000000000000000000", :give_amount => "1".to_wei, :take_token_address => "0x21921361bab476be44c0655256a2f4281bfcf07d", :take_amount => "1".to_wei },
      { :account_address => "0x76446f63c6b7756257b9c7d56ce7dde29836c203", :give_token_address => "0x0000000000000000000000000000000000000000", :give_amount => "1".to_wei, :take_token_address => "0x21921361bab476be44c0655256a2f4281bfcf07d", :take_amount => "1.1".to_wei },
      { :account_address => "0x76446f63c6b7756257b9c7d56ce7dde29836c203", :give_token_address => "0x0000000000000000000000000000000000000000", :give_amount => "1".to_wei, :take_token_address => "0x21921361bab476be44c0655256a2f4281bfcf07d", :take_amount => "1.2".to_wei },
      { :account_address => "0x76446f63c6b7756257b9c7d56ce7dde29836c203", :give_token_address => "0x0000000000000000000000000000000000000000", :give_amount => "1".to_wei, :take_token_address => "0x21921361bab476be44c0655256a2f4281bfcf07d", :take_amount => "1.3".to_wei },
      { :account_address => "0x76446f63c6b7756257b9c7d56ce7dde29836c203", :give_token_address => "0x0000000000000000000000000000000000000000", :give_amount => "1".to_wei, :take_token_address => "0x21921361bab476be44c0655256a2f4281bfcf07d", :take_amount => "1.4".to_wei },
      { :account_address => "0x76446f63c6b7756257b9c7d56ce7dde29836c203", :give_token_address => "0x21921361bab476be44c0655256a2f4281bfcf07d", :give_amount => "0.9".to_wei, :take_token_address => "0x0000000000000000000000000000000000000000", :take_amount => "1".to_wei },
      { :account_address => "0x76446f63c6b7756257b9c7d56ce7dde29836c203", :give_token_address => "0x21921361bab476be44c0655256a2f4281bfcf07d", :give_amount => "0.8".to_wei, :take_token_address => "0x0000000000000000000000000000000000000000", :take_amount => "1".to_wei },
      { :account_address => "0x76446f63c6b7756257b9c7d56ce7dde29836c203", :give_token_address => "0x21921361bab476be44c0655256a2f4281bfcf07d", :give_amount => "0.7".to_wei, :take_token_address => "0x0000000000000000000000000000000000000000", :take_amount => "1".to_wei },
      { :account_address => "0x76446f63c6b7756257b9c7d56ce7dde29836c203", :give_token_address => "0x21921361bab476be44c0655256a2f4281bfcf07d", :give_amount => "0.5".to_wei, :take_token_address => "0x0000000000000000000000000000000000000000", :take_amount => "1".to_wei },
      { :account_address => "0x76446f63c6b7756257b9c7d56ce7dde29836c203", :give_token_address => "0x21921361bab476be44c0655256a2f4281bfcf07d", :give_amount => "0.6".to_wei, :take_token_address => "0x0000000000000000000000000000000000000000", :take_amount => "1".to_wei },
    ])
    @trades = batch_trade([
      { :account_address => "0x76446f63c6b7756257b9c7d56ce7dde29836c203", :order_hash => @orders[0].order_hash, :amount => @orders[0].give_amount.to_i },
      { :account_address => "0x76446f63c6b7756257b9c7d56ce7dde29836c203", :order_hash => @orders[1].order_hash, :amount => @orders[1].give_amount.to_i },
      { :account_address => "0x76446f63c6b7756257b9c7d56ce7dde29836c203", :order_hash => @orders[2].order_hash, :amount => @orders[2].give_amount.to_i },
      { :account_address => "0x76446f63c6b7756257b9c7d56ce7dde29836c203", :order_hash => @orders[3].order_hash, :amount => @orders[3].give_amount.to_i },
      { :account_address => "0x76446f63c6b7756257b9c7d56ce7dde29836c203", :order_hash => @orders[4].order_hash, :amount => @orders[4].give_amount.to_i },
      { :account_address => "0x76446f63c6b7756257b9c7d56ce7dde29836c203", :order_hash => @orders[5].order_hash, :amount => @orders[5].give_amount.to_i },
      { :account_address => "0x76446f63c6b7756257b9c7d56ce7dde29836c203", :order_hash => @orders[6].order_hash, :amount => @orders[6].give_amount.to_i },
      { :account_address => "0x76446f63c6b7756257b9c7d56ce7dde29836c203", :order_hash => @orders[7].order_hash, :amount => @orders[7].give_amount.to_i },
      { :account_address => "0x76446f63c6b7756257b9c7d56ce7dde29836c203", :order_hash => @orders[8].order_hash, :amount => @orders[8].give_amount.to_i },
      { :account_address => "0x76446f63c6b7756257b9c7d56ce7dde29836c203", :order_hash => @orders[9].order_hash, :amount => @orders[9].give_amount.to_i },
    ])
  end

  test "should aggregate new data" do
    assert_difference('ChartDatum.count', markets.length) do
      ChartDatum.aggregate(1.hour)
    end
  end

  test "should remove expired data" do
    assert_difference('ChartDatum.count', -1) do
      ChartDatum.remove_expired
    end
  end
end
