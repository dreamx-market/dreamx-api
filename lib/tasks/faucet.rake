namespace :faucet do
  task :request_ether => :environment do
    uri = URI.parse("https://faucet.ropsten.be/donate/0x1C889f0E543CE8013D7c7CAa74613cA7d684c19e")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.get(uri.request_uri)
  end
end