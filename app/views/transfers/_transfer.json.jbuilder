json.extract! transfer, :id, :type, :token_address, :transaction_hash, :block_number, :created_at
json.amount transfer.amount.to_s