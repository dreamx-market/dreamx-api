require 'test_helper'

class OrderTest < ActiveSupport::TestCase
	setup do
		@order = orders(:one)
		@old_contract_address = ENV['CONTRACT_ADDRESS'].without_checksum
		ENV['CONTRACT_ADDRESS'] = "0x4ef6474f40bf5c9dbc013efaac07c4d0cb17219a"
	end

	teardown do
		ENV['CONTRACT_ADDRESS'] = @old_contract_address
	end

  test "automatically cancelled and refunded when market is disabled" do
    # we have invalid existing orders that cannot be cancelled
    @order.market.open_orders.destroy_all
    deposit_data = [
      { :account_address => @order.account_address, :token_address => @order.give_token_address, :amount => @order.give_amount }
    ]
    batch_deposit(deposit_data)
    original_balance = @order.account.balance(@order.give_token_address).balance

    new_order = Order.create(generate_order(@order))
    before_cancel_balance = @order.account.balance(@order.give_token_address).balance
    begin
      assert_not_equal original_balance, before_cancel_balance
    rescue
      byebug
    end

    new_order.market.disable
    new_order.reload
    after_cancel_balance = @order.account.balance(@order.give_token_address).balance
    assert_equal original_balance, after_cancel_balance
    assert_equal new_order.status, 'closed'
  end

  test "sell orders volume must be greater than minimum on create" do
    new_sell_order = Order.new(:account_address => @order.account_address, :give_token_address => @order.give_token_address, :give_amount => @order.give_amount, :take_token_address => @order.take_token_address, :take_amount => ENV['MAKER_MINIMUM_ETH_IN_WEI'].to_i - 1, :nonce => 0, :expiry_timestamp_in_milliseconds => @order.expiry_timestamp_in_milliseconds, :order_hash => @order.order_hash, :signature => @order.signature)
    assert_not new_sell_order.valid?
    assert_equal new_sell_order.errors.messages[:take_amount], ["must be greater than #{ENV['MAKER_MINIMUM_ETH_IN_WEI']}"]
  end

  test "buy orders volume must be greater than minimum on create" do
    new_buy_order = Order.new(:account_address => @order.account_address, :give_token_address => @order.take_token_address, :give_amount => ENV['MAKER_MINIMUM_ETH_IN_WEI'].to_i - 1, :take_token_address => @order.give_token_address, :take_amount => ENV['MAKER_MINIMUM_ETH_IN_WEI'].to_i - 1, :nonce => 0, :expiry_timestamp_in_milliseconds => @order.expiry_timestamp_in_milliseconds, :order_hash => @order.order_hash, :signature => @order.signature)
    assert_not new_buy_order.valid?
    assert_equal new_buy_order.errors.messages[:give_amount], ["must be greater than #{ENV['MAKER_MINIMUM_ETH_IN_WEI']}"]
  end

  test "updating MAKER_MINIMUM does not invalidate existing orders" do
    assert_equal @order.valid?, true
    old_minimum_volume = ENV['MAKER_MINIMUM_ETH_IN_WEI']

    ENV['MAKER_MINIMUM_ETH_IN_WEI'] = (@order.volume.to_i * 2).to_s
    assert_equal @order.valid?, true
  end
end
