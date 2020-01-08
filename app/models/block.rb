class Block < ApplicationRecord
  def self.process_new_confirmed_blocks
    ActiveRecord::Base.transaction do
      client = Ethereum::Singleton.instance
      current_block_number = client.eth_block_number["result"].hex
      last_block = Block.find_or_create_by({ id: 1 })
      last_block_number = last_block.block_number
      required_confirmations = ENV['TRANSACTION_CONFIRMATIONS'].to_i

      @last_confirmed_block_number = current_block_number - required_confirmations
      @last_processed_block_number = last_block ? last_block.block_number : @last_confirmed_block_number

      if (current_block_number < required_confirmations || last_block.block_number == @last_confirmed_block_number)
        return
      end

      self.before_processing

      (@last_processed_block_number..@last_confirmed_block_number).step(1) do |i|
        current_block = client.eth_get_block_by_number(i, false).convert_keys_to_underscore_symbols![:result]

        self.process(current_block)

        last_block.assign_attributes({
          block_number: current_block[:number].hex,
          block_hash: current_block[:hash],
          parent_hash: current_block[:parent_hash]
        })
      end

      self.after_processing

      last_block.save!
    end
  end

  def self.process(current_block)
    Transaction.confirm_mined_transactions(current_block)
    # Transaction.broadcast_expired_transactions
  end

  def self.before_processing
    Deposit.aggregate(@last_confirmed_block_number, @last_processed_block_number)
  end

  def self.after_processing
  end
end
