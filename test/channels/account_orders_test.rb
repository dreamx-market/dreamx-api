require 'test_helper'
 
class AccountOrdersTest < ActionCable::TestCase
  include ActiveJob::TestHelper

  setup do
    @order = orders(:one)

    deposit_data = [
      { :account_address => @order.account_address, :token_address => @order.give_token_address, :amount => @order.give_amount }
    ]
    batch_deposit(deposit_data)
  end

  test "broadcast a message when a new order is created" do
    new_order = Order.new(generate_order(@order))

    assert_broadcasts("account_orders:#{new_order.account_address}", 1) do
      perform_enqueued_jobs do
        new_order.save
      end
    end
  end
end