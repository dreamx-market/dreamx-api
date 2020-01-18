class Etherscan
  def self.send_request(url)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    response = JSON.parse(http.get(uri.request_uri).body).convert_keys_to_underscore_symbols!
  end

  def self.get_event_logs(contract, event_name, from, to=from)
    encoder = Ethereum::Encoder.new
    event_signature = encoder.ensure_prefix(contract.events.find { |event| event.name == event_name }.signature)
    api_root = ENV['ETHERSCAN_HTTP']
    api_key = ENV['ETHERSCAN_API_KEY']
    contract_address = contract.address

    url = "#{api_root}?module=logs&action=getLogs"\
          "&fromBlock=#{from}"\
          "&toBlock=#{to}"\
          "&address=#{contract_address}"\
          "&topic0=#{event_signature}"\
          "&apikey=#{api_key}"
    event_logs_response = self.send_request(url)

    event_logs = []
    event_logs_response[:result].each do |e|
      event_logs << e
    end
    return event_logs
  end

  def self.get_approval_event_logs(token_contract, from, to)
    encoder = Ethereum::Encoder.new
    event_signature = encoder.ensure_prefix(token_contract.events.find { |event| event.name == 'Approval' }.signature)
    api_root = ENV['ETHERSCAN_HTTP']
    api_key = ENV['ETHERSCAN_API_KEY']
    contract_address = token_contract.address
    exchange_address = Contract::Exchange.singleton.contract.address
    padded_exchange_address = Eth::Utils.bin_to_prefixed_hex(Eth::Utils.zpad(Eth::Utils.hex_to_bin(exchange_address), 32))

    url = "#{api_root}?module=logs&action=getLogs"\
          "&fromBlock=#{from}"\
          "&toBlock=#{to}"\
          "&address=#{contract_address}"\
          "&topic0=#{event_signature}"\
          "&topic0_2_opr=and"\
          "&topic2=#{padded_exchange_address}"\
          "&apikey=#{api_key}"
    event_logs_response = self.send_request(url)

    event_logs = []
    event_logs_response[:result].each do |e|
      event_logs << e
    end
    return event_logs
  end

  def self.get_transactions(from, to=from)
    transactions = []
    api_root = ENV['ETHERSCAN_HTTP']
    api_key = ENV['ETHERSCAN_API_KEY']
    key = Eth::Key.new(priv: ENV['SERVER_PRIVATE_KEY'].hex)
    account_address = key.address

    transactions_response = self.send_request("#{api_root}?module=account&action=txlist&startblock=#{from}&endblock=#{to}&address=#{account_address}&apikey=#{api_key}")

    transactions = transactions_response[:result].map { |transaction| transaction[:hash] }
    return transactions
  end
end