class Block < ApplicationRecord
  def self.process_new_confirmed_blocks
    client = Ethereum::Singleton.instance
    required_confirmations = ENV['TRANSACTION_CONFIRMATIONS'].to_i

    current_block = client.eth_get_block_by_number('latest', false).convert_keys_to_underscore_symbols![:result]
    current_block_number = current_block[:number].hex
    last_block = Block.find_or_create_by({ id: 1 })
    last_block_number = last_block.block_number
    last_confirmed_block_number = current_block_number - required_confirmations
    last_processed_block_number = last_block ? last_block.block_number : last_confirmed_block_number

    if (current_block_number < required_confirmations || last_block.block_number == last_confirmed_block_number)
      return
    end

    self.process(last_processed_block_number + 1, last_confirmed_block_number)

    last_block.update!(block_number: last_confirmed_block_number)
  end

  def self.process(from, to)
    Deposit.aggregate(from, to)
    Transaction.confirm_mined_transactions(from, to)
  end
end
