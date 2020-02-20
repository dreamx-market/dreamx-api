json.extract! order, :account_address, :give_token_address, :take_token_address, :status, :nonce, :expiry_timestamp_in_milliseconds, :order_hash, :sell, :created_at, :market_symbol
json.give_amount order.give_amount.to_s
json.take_amount order.take_amount.to_s
json.filled order.filled.to_s
json.price order.price.to_s
