json.extract! order, :id, :account, :giveTokenAddress, :giveAmount, :takeTokenAddress, :takeAmount, :nonce, :expiryTimestampInMilliseconds, :orderHash, :signature, :created_at, :updated_at
json.url order_url(order, format: :json)
