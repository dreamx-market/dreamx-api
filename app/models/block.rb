class Block < ApplicationRecord
  def self.process_new_confirmed_blocks
    if Config.get('processing_new_blocks') == 'false'
      return
    end

    last_block = Block.find_or_create_by({ id: 1 })
    client = Ethereum::Singleton.instance
    required_confirmations = ENV['TRANSACTION_CONFIRMATIONS'].to_i
    current_block = client.eth_get_block_by_number('latest', false).convert_keys_to_underscore_symbols![:result]
    current_block_number = current_block[:number].hex
    last_block_number = last_block.block_number
    last_confirmed_block_number = current_block_number - required_confirmations
    last_processed_block_number = last_block ? last_block.block_number : last_confirmed_block_number

    if (current_block_number < required_confirmations || last_block.block_number == last_confirmed_block_number)
      return
    end

    begin
      ActiveRecord::Base.transaction do
        self.process(last_processed_block_number + 1, last_confirmed_block_number)
        last_block.update!(block_number: last_confirmed_block_number)
        Redis.current.set('gas_price', Etherscan.gas_price)
      end
    rescue => err
      AppLogger.log("Failed to process new blocks from #{last_processed_block_number + 1} to #{last_confirmed_block_number}, received following error: #{err}")
    end
  end

  def self.process(from, to=from)
    Deposit.aggregate(from, to)
    Ejection.aggregate(from, to)
    Transaction.confirm_transactions(from, to)
  end
end
