json.base_token do
	json.extract! market.base_token, :name, :symbol, :decimals, :address
end
json.quote_token do
	json.extract! market.quote_token, :name, :symbol, :decimals, :address
end
