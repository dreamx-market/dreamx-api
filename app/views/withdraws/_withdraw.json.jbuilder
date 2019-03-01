json.extract! withdraw, :id, :account_address, :amount, :token_address, :nonce, :withdraw_hash, :signature, :created_at, :updated_at
json.url withdraw_url(withdraw, format: :json)
