module Contract
  class ERC20
    attr_accessor :contract

    class << self
      def singletons(token_symbol, token_address)
        @singletons ||= {}
        @singletons[token_symbol] ||= self.new(token_address)
      end
    end

    def initialize(token_address)
      @abi = JSON.parse(File.read("#{__dir__}/artifacts/ERC20.json"))["abi"]
      @contract = Ethereum::Contract.create(name: "ERC20", address: token_address, abi: @abi) # do not use "Token" for name or it will override the existing Token model
    end

    def approvals(from, to=from)
      decoder = Ethereum::Decoder.new
      encoder = Ethereum::Encoder.new
      event_name = 'Approval'

      event_abi = @abi.find { |a| a['name'] == event_name }
      event_inputs = event_abi['inputs'].map { |i| OpenStruct.new(i) }
      event_indexed_input = event_inputs.select(&:indexed)
      event_unindexed_input = event_inputs.reject(&:indexed)

      event_logs = Etherscan.get_approval_event_logs(@contract, from, to)
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

        prefixed_attrs = [:owner, :spender]
        prefixed_attrs.each do |attr|
          if decoded_event[attr]
            decoded_event[attr] = encoder.ensure_prefix(decoded_event[attr])
          end
        end

        decoded_events << decoded_event
      end
      return decoded_events
    end
  end
end