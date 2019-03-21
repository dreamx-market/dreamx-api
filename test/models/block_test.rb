require 'test_helper'

class BlockTest < ActiveSupport::TestCase
  test "should process new blocks" do
    assert_difference('Deposit.count') do
      Block.process_new_confirmed_blocks
    end
  end
end
