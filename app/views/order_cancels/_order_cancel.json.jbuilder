json.extract! order_cancel, :id, :order_hash, :account_address, :nonce, :cancel_hash, :signature, :created_at, :updated_at
json.url order_cancel_url(order_cancel, format: :json)
