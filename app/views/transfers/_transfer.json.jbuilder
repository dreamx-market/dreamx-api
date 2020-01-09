json.extract! transfer, :id, :type, :token_address, :transaction_hash, :status, :created_at
json.amount transfer.amount.to_s