class Etherscan
  def self.send_request(url)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    response = JSON.parse(http.get(uri.request_uri).body).convert_keys_to_underscore_symbols!
  end

  def self.get_event_logs(name, from, to=from)
    encoder = Ethereum::Encoder.new
    contract = Contract::Exchange.singleton.contract
    event_signature = encoder.ensure_prefix(contract.events.find { |event| event.name == name }.signature)
    api_root = ENV['ETHERSCAN_HTTP']
    api_key = ENV['ETHERSCAN_API_KEY']
    contract_address = ENV['CONTRACT_ADDRESS']

    event_logs_response = self.send_request("#{api_root}?module=logs&action=getLogs&fromBlock=#{from}&toBlock=#{to}&address=#{contract_address}&topic0=#{event_signature}&apikey=#{api_key}")

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