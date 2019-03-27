json.extract! transaction, :id, :action_type, :action_hash, :raw, :gas_limit, :gas_price, :hash, :block_hash, :block_number, :status, :nonce, :created_at, :updated_at
json.url transaction_url(transaction, format: :json)
