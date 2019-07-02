key = Eth::Key.new(priv: ENV['SERVER_PRIVATE_KEY'].hex)
Ethereum::Singleton.client = :http
Ethereum::Singleton.host = ENV['ETHEREUM_HOST']
Ethereum::Singleton.default_account = key.address
Eth.configure do |config|
  chain_id = Ethereum::Singleton.instance.net_version["result"].to_i
  config.chain_id = chain_id
end
