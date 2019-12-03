class Block < ApplicationRecord
  def self.process_new_confirmed_blocks
    client = Ethereum::Singleton.instance
    current_block = client.eth_block_number["result"].hex
    saved_block = self.last

    saved_block.with_lock do
      required_confirmations = ENV['TRANSACTION_CONFIRMATIONS'].to_i
      last_confirmed_block_number = current_block - required_confirmations
      last_processed_block_number = saved_block ? saved_block.block_number : last_confirmed_block_number
      last_block_number = last_processed_block_number

      if (current_block < required_confirmations or (saved_block and saved_block.block_number == last_confirmed_block_number))
        return
      end

      (last_processed_block_number..last_confirmed_block_number).step(1) do |i|
        self.process_block(i)
        last_block_number = i
      end

      last_block = client.eth_get_block_by_number(last_block_number, false)

      if (!saved_block)
        saved_block = Block.create(:id => 1)
      end

      saved_block.update!(:block_number => last_block["result"]["number"].hex, :block_hash => last_block["result"]["hash"], :parent_hash => last_block["result"]["parentHash"])
    end
  end

  def self.process_block(block_number)
    # the following methods should be able to be called multiple times 
    # with the same arguments without causing errors for scenarios where block#1 is reverted
    # to an earlier block number
    Deposit.aggregate(block_number)
  end

  def self.revert_to_block(block_number)
    last_block = self.last

    if !last_block
      return
    end

    last_block.with_lock do
      last_block.update!({ :block_number => block_number })
    end
  end
end
