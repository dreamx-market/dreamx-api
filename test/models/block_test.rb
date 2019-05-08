require 'test_helper'

class BlockTest < ActiveSupport::TestCase
  test "should process new blocks" do
    assert_changes('Deposit.count') do
      Block.process_new_confirmed_blocks
    end
  end

  test "should be able to revert to an earlier block" do
    assert_changes('Deposit.count') do
      Block.process_new_confirmed_blocks
    end

    Block.revert_to_block(0)

    assert_no_changes('Deposit.count') do
      Block.process_new_confirmed_blocks
    end
  end
end
