json.extract! trade, :id, :account_address, :order_hash, :amount, :nonce, :trade_hash, :signature, :uuid, :created_at, :updated_at
json.url trade_url(trade, format: :json)
