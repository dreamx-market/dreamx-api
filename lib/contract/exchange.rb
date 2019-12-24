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

    def deposits(from=1, to=from)
      decoder = Ethereum::Decoder.new
      encoder = Ethereum::Encoder.new
      client = Ethereum::Singleton.instance

      deposit_event_signature = encoder.ensure_prefix(@contract.events.find { |event| event.name == 'Deposit' }.signature)
      deposit_event_abi = @abi.find { |a| a['name'] == 'Deposit' }
      deposit_event_inputs = deposit_event_abi['inputs'].map { |i| OpenStruct.new(i) }
      deposit_event_indexed_inputs = deposit_event_inputs.select(&:indexed)
      deposit_event_unindexed_inputs = deposit_event_inputs.reject(&:indexed)

      incoming_transactions = []
      (from..to).step(1) do |i|
        block = client.eth_get_block_by_number(i, true)['result']
        if block
          block['transactions'].each do |t|
            if t['to'].nil? or !Eth::Utils.valid_address?(t['to'])
              next
            end

            if t['to'].without_checksum == @contract.address.without_checksum
              incoming_transactions << t
            end
          end
        end
      end

      deposit_logs = []
      incoming_transactions.each do |t|
        transaction = client.eth_get_transaction_receipt(t['hash'])
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

    def account_manual_withdraws(account_address)
      @contract.call.account_manual_withdraws(account_address)
    end
  end
end