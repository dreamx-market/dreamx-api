module Contract
  class Exchange
    attr_accessor :contract

    class << self
      def singleton
        @singleton ||= new
      end
    end

    def initialize
      @abi = JSON.parse(File.read("#{__dir__}/artifacts/Exchange.json"))["abi"]
      @contract = Ethereum::Contract.create(name: "Exchange", address: ENV['CONTRACT_ADDRESS'].without_checksum, abi: @abi)
      @contract.key = Eth::Key.new(priv: ENV['SERVER_PRIVATE_KEY'].hex)
    end

    def get_events(name, from, to=from)
      decoder = Ethereum::Decoder.new
      encoder = Ethereum::Encoder.new
      client = Ethereum::Singleton.instance
      name = name.capitalize

      event_abi = @abi.find { |a| a['name'] == name }
      event_inputs = event_abi['inputs'].map { |i| OpenStruct.new(i) }
      event_indexed_input = event_inputs.select(&:indexed)
      event_unindexed_input = event_inputs.reject(&:indexed)

      event_logs = Etherscan.get_event_logs(name, from, to)
      decoded_events = []
      event_logs.each do |event_log|
        indexed_data = '0x' + event_log[:topics][1..-1].join.gsub('0x', '')
        indexed_args = decoder.decode_arguments(event_indexed_input, indexed_data)
        unindexed_data = event_log[:data]
        unindexed_args = decoder.decode_arguments(event_unindexed_input, unindexed_data)
        args = indexed_args.concat(unindexed_args)

        decoded_event = {}
        decoded_event[:transaction_hash] = event_log[:transaction_hash]
        decoded_event[:block_number] = event_log[:block_number].hex
        args.each_with_index do |arg, i|
          decoded_event[event_inputs[i].name.to_sym] = arg
        end

        prefixed_attrs = [:token, :account]
        prefixed_attrs.each do |attr|
          if decoded_event[attr]
            decoded_event[attr] = encoder.ensure_prefix(decoded_event[attr])
          end
        end

        decoded_events << decoded_event
      end
      return decoded_events
    end

    def deposits(from, to=from)
      self.get_events('deposit', from, to)
    end

    def ejections(from, to=from)
      self.get_events('ejection', from, to)
    end

    def balances(token_address, account_address)
      @contract.call.balances(token_address, account_address)
    end

    def functions(function_name)
      if !function_name
        return @contract.parent.functions
      else
        return @contract.parent.functions.select { |fun| fun.name == function_name}.first
      end
    end

    def call_payload(fun, args)
      @contract.parent.call_payload(fun, args)
    end
  end
end