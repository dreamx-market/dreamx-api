json.address ENV['CONTRACT_ADDRESS'].without_checksum
json.network_id Eth.chain_id.to_s