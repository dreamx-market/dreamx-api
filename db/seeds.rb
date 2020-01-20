# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# currencies = [
# 	{ :symbol => "ETH", :decimals => 18, :address => "0x0000000000000000000000000000000000000000", :name => "Ether" },
# 	{ :symbol => "REP", :decimals => 18, :address => "0xc853ba17650d32daba343294998ea4e33e7a48b9", :name => "Reputation" },
# 	{ :symbol => "TRX", :decimals => 8, :address => "0xf59fad2879fb8380ffa6049a48abf9c9959b3b5c", :name => "Tron" }
# ]
# currencies.each { |currency| Currency.create currency }

networks = { "1" => "mainnet", "42" => "kovan", "3" => "ropsten", "4" => "rinkeby" }
tokens = []
markets = []

if (networks[Eth.chain_id.to_s] == "mainnet")
  # TODO: implement mainnet seeds
end

if (networks[Eth.chain_id.to_s] == "ropsten")
  tokens = [
    { :name => "One", :address => "0xe62cc4212610289d7374f72c2390a40e78583350", :symbol => "ONE", :decimals => "18", :amount_precision => 2, :withdraw_minimum => "20000000000000000", :withdraw_fee => "10000000000000000" },
    { :name => "Two", :address => "0x629c21172f58df81585fbc53f50cc601e90e031d", :symbol => "TWO", :decimals => "18", :amount_precision => 5, :withdraw_minimum => "20000000000000000", :withdraw_fee => "10000000000000000" },
    { :name => "Ethereum", :address => "0x0000000000000000000000000000000000000000", :symbol => "ETH", :decimals => "18", :amount_precision => 4, :withdraw_minimum => "20000000000000000", :withdraw_fee => "10000000000000000" }
  ]
  markets = [
    { :base_token_address => "0x0000000000000000000000000000000000000000", :quote_token_address => "0xe62cc4212610289d7374f72c2390a40e78583350", :status => "active", :price_precision => 6 },
    { :base_token_address => "0x0000000000000000000000000000000000000000", :quote_token_address => "0x629c21172f58df81585fbc53f50cc601e90e031d", :status => "active", :price_precision => 2 }
  ]
end

Token.create(tokens)
Market.create(markets)
