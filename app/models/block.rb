class Block < ApplicationRecord
  def self.process_new_confirmed_blocks
    @client ||= Ethereum::Singleton.instance
    current_block = @client.eth_block_number["result"].hex

    if (current_block < 12)
      return
    end

    last_confirmed_block_number = current_block - ENV['TRANSACTION_CONFIRMATIONS'].to_i
    last_processed_block_number = self.last ? self.last.block_number : 0
    last_block_number = last_processed_block_number

    (last_processed_block_number..last_confirmed_block_number).step(1) do |i|
      self.process_block(i)
      last_block_number = i
    end

    last_block = @client.eth_get_block_by_number(last_block_number, false)
    self.find_or_initialize_by(:id => 1).update!(:block_number => last_block["result"]["number"].hex, :block_hash => last_block["result"]["hash"], :parent_hash => last_block["result"]["parentHash"])
  end

  def self.process_block(block_number)
    Deposit.aggregate(block_number)
  end
end
