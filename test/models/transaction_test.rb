require 'test_helper'

class TransactionTest < ActiveSupport::TestCase
  setup do
    @transaction = transactions(:one)
  end

  test "has transactable" do
    assert_not_nil @transaction.transactable
  end
end
