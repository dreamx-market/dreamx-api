class Block < ApplicationRecord
  def self.process_new_confirmed_blocks
    client = Ethereum::Singleton.instance
    current_block = client.eth_block_number["result"].hex
    saved_block = Block.find_or_create_by({ id: 1 })
    required_confirmations = ENV['TRANSACTION_CONFIRMATIONS'].to_i

    last_confirmed_block_number = current_block - required_confirmations
    last_processed_block_number = saved_block ? saved_block.block_number : last_confirmed_block_number

    if (current_block < required_confirmations || saved_block.block_number == last_confirmed_block_number)
      return
    end

    (last_processed_block_number..last_confirmed_block_number).step(1) do |i|
      block = client.eth_get_block_by_number(i, true)
      self.process_block(block)
      last_block = block
    end

    saved_block.update!(:block_number => last_block["result"]["number"].hex, :block_hash => last_block["result"]["hash"], :parent_hash => last_block["result"]["parentHash"])
  end

  def self.process_block(block)
    Deposit.aggregate(block)
  end
end
