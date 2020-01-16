json.extract! token, :name, :address, :symbol, :decimals, :amount_precision
json.withdraw_minimum token.withdraw_minimum.to_s
json.withdraw_fee token.withdraw_fee.to_s
