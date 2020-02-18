json.extract! trade, :id, :give_token_address, :take_token_address, :order_hash, :maker_address, :taker_address, :transaction_hash, :created_at, :market_symbol
json.give_amount trade.give_amount.to_s
json.take_amount trade.take_amount.to_s
json.maker_fee trade.maker_fee.to_s
json.taker_fee trade.taker_fee.to_s
