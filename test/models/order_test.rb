require 'test_helper'

class OrderTest < ActiveSupport::TestCase
	setup do
		@order = orders(:one)
	end

	test "amounts cannot be 0" do
  	@order.give_amount = 0
  	@order.take_amount = 0
  	assert_not @order.valid?
  end

  test "expiry timestamp must be in the future" do
  	@order.expiry_timestamp_in_milliseconds = 10.days.ago
  	assert_not @order.valid?
  end
end
