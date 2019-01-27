# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

currencies = [
	{ :symbol => "ETH", :decimals => 18, :address => "0x0000000000000000000000000000000000000000", :name => "Ether" },
	{ :symbol => "REP", :decimals => 18, :address => "0xc853ba17650d32daba343294998ea4e33e7a48b9", :name => "Reputation" },
	{ :symbol => "TRX", :decimals => 8, :address => "0xf59fad2879fb8380ffa6049a48abf9c9959b3b5c", :name => "Tron" }
]
currencies.each { |currency| Currency.create currency }