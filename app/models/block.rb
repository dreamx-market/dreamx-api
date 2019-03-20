class Block < ApplicationRecord
  def self.process_new_blocks
    # iterate from Block.last.number to latest block
    # do shit
    # update or create Block.last if it doesn't exist
  end
end
