require 'test_helper'

class OrderCancelTest < ActiveSupport::TestCase
  setup do
    @order_cancel = order_cancels(:one)
    @old_contract_address = ENV['CONTRACT_ADDRESS']
    ENV['CONTRACT_ADDRESS'] = "0x4ef6474f40bf5c9dbc013efaac07c4d0cb17219a"
  end

  teardown do
    ENV['CONTRACT_ADDRESS'] = @old_contract_address
  end

  test "order with order_hash must exist" do
    @order_cancel.order_hash = 'INVALID'
    assert_not @order_cancel.valid?
    assert_equal @order_cancel.errors.messages[:order], ["must exist"]
  end

  test "order must be open" do
    @order_cancel.order.status = 'closed'
    assert_not @order_cancel.valid?
    assert_equal @order_cancel.errors.messages[:order_hash], ["must be open"]
  end

  test "account_address must owns the order" do
    @order_cancel.order.account_address = 'someone_else'
    assert_not @order_cancel.valid?
    assert_equal @order_cancel.errors.messages[:account_address], ["must be owner"]
  end

  test "nonce must be greater than last nonce" do
    new_order_cancel = OrderCancel.new({ :nonce => 1 })
    assert_not new_order_cancel.valid?
    assert_equal new_order_cancel.errors.messages[:nonce], ["must be greater than last nonce"]
  end

  test "cancel_hash must be valid" do
    @order_cancel.cancel_hash = 'INVALID'
    assert_not @order_cancel.valid?
    assert_equal @order_cancel.errors.messages[:cancel_hash], ["invalid"]
  end

  test "signature must be valid" do
    @order_cancel.signature = 'INVALID'
    assert_not @order_cancel.valid?
    assert_equal @order_cancel.errors.messages[:signature], ["invalid"]
  end
end
