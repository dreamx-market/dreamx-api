module Contract
  class Exchange
    attr_accessor :instance, :abi

    class << self
      def singleton
        @singleton ||= new
      end
    end

    def initialize
      @abi = JSON.parse(File.read("#{__dir__}/contracts/Exchange.json"))["abi"]
      @instance = Ethereum::Contract.create(name: "Exchange", address: ENV['CONTRACT_ADDRESS'], abi: @abi)
      @instance.key = Eth::Key.new(priv: ENV['PRIVATE_KEY'].hex)
    end

    def deposits(from, to=nil)
      if from == 0
        from = 1
      end

      decoder = Ethereum::Decoder.new
      encoder = Ethereum::Encoder.new
      client = Ethereum::Singleton.instance

      deposit_event_signature = encoder.ensure_prefix(@instance.events.find { |event| event.name == 'Deposit' }.signature)
      deposit_event_abi = @abi.find { |a| a['name'] == 'Deposit' }
      deposit_event_inputs = deposit_event_abi['inputs'].map { |i| OpenStruct.new(i) }
      deposit_event_indexed_inputs = deposit_event_inputs.select(&:indexed)
      deposit_event_unindexed_inputs = deposit_event_inputs.reject(&:indexed)

      filter_id = @instance.new_filter.deposit(
        {
          from_block: from,
          to_block: to || from,
          topics: []
        }
      )

      deposit_events = @instance.get_filter_logs.deposit(filter_id)

      deposit_logs = []
      deposit_events.each do |event|
        transaction = client.eth_get_transaction_receipt(event[:transactionHash])
        transaction['result']['logs'].each do |log|
          deposit_logs << log if log['topics'][0] == deposit_event_signature
        end
      end

      decoded_deposits = []
      deposit_logs.each do |deposit_log|
        indexed_data = '0x' + deposit_log['topics'][1..-1].join.gsub('0x', '')
        indexed_args = decoder.decode_arguments(deposit_event_indexed_inputs, indexed_data)
        unindexed_data = deposit_log['data']
        unindexed_args = decoder.decode_arguments(deposit_event_unindexed_inputs, unindexed_data)
        args = indexed_args.concat unindexed_args

        decoded_deposit = {}
        decoded_deposit['transaction_hash'] = deposit_log['transactionHash']
        decoded_deposit['block_hash'] = deposit_log['blockHash']
        decoded_deposit['block_number'] = deposit_log['blockNumber'].hex
        args.each_with_index do |arg, i|
          decoded_deposit[deposit_event_inputs[i].name] = arg
        end

        decoded_deposit_prefixed_attr = [:token, :account]
        decoded_deposit_prefixed_attr.each do |attr|
          decoded_deposit["#{attr}"] = encoder.ensure_prefix(decoded_deposit["#{attr}"])
        end

        decoded_deposits << decoded_deposit
      end

      # [ { :transaction_hash, :block_hash, :block_number, :token, :account, :amount, :balance }, ... ]
      return decoded_deposits
    end
  end
end