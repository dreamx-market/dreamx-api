class Etherscan
  def self.send_request(url)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    raw_response = http.get(uri.request_uri)
    if (raw_response.code != "200")
      AppLogger.log(response)
    end
    response = JSON.parse(raw_response.body).convert_keys_to_underscore_symbols!
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