class Block < ApplicationRecord
  def self.process_new_confirmed_blocks
    @client ||= Ethereum::Singleton.instance
    current_block = @client.eth_block_number["result"].hex

    if (current_block < 12)
      return
    end

    last_confirmed_block_number = current_block - ENV['TRANSACTION_CONFIRMATIONS'].to_i
    last_processed_block_number = self.last ? self.last.number : 0
    last_block = nil

    Integer(last_confirmed_block_number - last_processed_block_number).times do |i|
      new_block_number = last_processed_block_number + i + 1
      new_block = @client.eth_get_block_by_number(new_block_number, false)
      self.process_block(new_block)
      last_block = new_block
    end

    self.find_or_initialize_by(:id => 1).update!(:block_number => last_block["result"]["number"].hex, :block_hash => last_block["result"]["hash"], :parent_hash => last_block["result"]["parentHash"])
  end

  def self.process_block(block)
  end
end
