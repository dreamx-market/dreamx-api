class Block < ApplicationRecord
  def self.process_new_confirmed_blocks
    block = self.find_or_initialize_by(:id => 1)

    if block.status == 'pending'
      return
    else
      block.update!(:status => 'pending')
    end

    @client ||= Ethereum::Singleton.instance
    current_block = @client.eth_block_number["result"].hex

    required_confirmations = ENV['TRANSACTION_CONFIRMATIONS'].to_i
    last_confirmed_block_number = current_block - required_confirmations
    last_processed_block_number = self.last ? self.last.block_number : last_confirmed_block_number
    last_block_number = last_processed_block_number

    if (current_block < required_confirmations or (self.last and self.last.block_number == last_confirmed_block_number))
      return
    end

    (last_processed_block_number..last_confirmed_block_number).step(1) do |i|
      self.process_block(i)
      last_block_number = i
    end

    last_block = @client.eth_get_block_by_number(last_block_number, false)
    block.update!(:status => 'completed', :block_number => last_block["result"]["number"].hex, :block_hash => last_block["result"]["hash"], :parent_hash => last_block["result"]["parentHash"])
  end

  def self.process_block(block_number)
    # the following methods should be able to be called multiple times 
    # with the same arguments without causing errors
    Deposit.aggregate(block_number)
  end

  def self.revert_to_block(block_number)
    if !self.last
      return
    end

    self.last.update!({ :block_number => block_number })
  end
end
