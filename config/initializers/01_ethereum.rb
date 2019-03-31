Ethereum::Singleton.client = :http
Ethereum::Singleton.host = ENV['ETHEREUM_HOST']
Eth.configure do |config|
  chain_id = Ethereum::Singleton.instance.net_version["result"].to_i
  config.chain_id = chain_id
end
