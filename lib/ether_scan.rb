class Etherscan
  def self.get_deposit_logs(from, to=from)
    encoder = Ethereum::Encoder.new
    contract = Contract::Exchange.singleton.contract
    deposit_event_signature = encoder.ensure_prefix(contract.events.find { |event| event.name == 'Deposit' }.signature)
    api_root = ENV['ETHERSCAN_HTTP']
    api_key = ENV['ETHERSCAN_API_KEY']
    contract_address = ENV['CONTRACT_ADDRESS']

    uri = URI.parse("#{api_root}?module=logs&action=getLogs&fromBlock=#{from}&toBlock=#{to}&address=#{contract_address}&topic0=#{deposit_event_signature}&apikey=#{api_key}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    response = JSON.parse(http.get(uri.request_uri).body).convert_keys_to_underscore_symbols!

    deposit_logs = []
    response[:result].each do |e|
      deposit_logs << e
    end

    return deposit_logs
  end
end