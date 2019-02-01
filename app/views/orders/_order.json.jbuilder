json.extract! order, :id, :account, :give_token_address, :give_amount, :take_token_address, :take_amount, :nonce, :expiry_timestamp_in_milliseconds, :order_hash, :signature, :created_at, :updated_at
json.url order_url(order, format: :json)
