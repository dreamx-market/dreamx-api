def sync_nonce
  client = Ethereum::Singleton.instance
  key = Eth::Key.new priv: ENV['SERVER_PRIVATE_KEY'].hex
  Redis.current.set("nonce", client.get_nonce(key.address))
end

def sync_balance(balance)
  new_balance = balance.onchain_balance.to_i - balance.hold_balance.to_i
  balance.credit(new_balance)
end

def private_keys
  {
    "0xe37a4faa73fced0a177da51d8b62d02764f2fc45" => 0xd15b17f51f613d0d89c64c7b629ffff7ae9c19e509afc9518dac1650e9812c18, # has 1000 ETH, ONE and TWO onchain
    "0xa77344043e0b0bada9318f41803e07e9dfc57b0b" => 0xf1caff04b5ff349674820a4eb6ee11c459ad3698ca581c8a8e82ee09591b7aa2, # has 1000 ETH onchain
    "0xbfd525710ecb49a266337683971bac0d72d746a6" => 0x24b39c598f81d10af245a6b0c1733be41b63ce4d7ea2e694535a2d1c3730c7b9,
    "0xfa46ed8f8d3f15e7d820e7246233bbd9450903e3" => 0x481118f6ea0f477469c7040fdb5fda6d9e2b32a5eea79b68256a20498815ba34,
    "0x266a483b876c85fb10c1bd0933e3e64e7ce4ecbb" => 0xf67a9579d888aee21c9ecfb7e9bfbb03940f4e20ee34bab2a3e3aa0c3832bff3,
    "0x16e86d3935e8922a9b14c722a97552a202575256" => 0xa23c19df2d411241cd5f6fdef64333e43475c7ee1fb626dd9c956284fd8ceca0,
    "0x9a94af493513afc3873c5b6eced09874f0a6f751" => 0x6ffbd5ff2ac4762f0d3e06ed3e253441ff9802bd9fab89bcc0996a5fb737e460,
    "0xae5e918b65623660701586ca187c9485c03334bb" => 0xdb3e755d28ee954bdff322be697ba57dd797b6aa8e0dd4ef1edc52ae280e79e9,
    "0xf06abaa2ff45cd469c2dab6ad9f8848ce12850d1" => 0xb2be1b7f9e3bb42b30d200623a03fc9dbbf840802567073250e3b6fdff6d3f6e,
    "0xcc6cfe1a7f27f84309697beeccbc8112a6b7240a" => 0xa936c57c1e46cec1f70a336c32ecc751bc465070da3fe556d526a082542cc177,
    "0x76446f63c6b7756257b9c7d56ce7dde29836c203" => 0x2b615c2e8ab0fa8ec8c711b5c20c7715d5bb823a40398db9df46f994ab5d53e2
  }
end

def addresses
  private_keys.keys
end

def token_addresses
  {
    "ETH" => "0x0000000000000000000000000000000000000000",
    "ONE" => "0x8137064a86006670d407c24e191b5a55da5b2889",
    "TWO" => "0x75d417ab3031d592a781e666ee7bfc3381ad33d5"
  }
end

def snapshot_blockchain
  client = Ethereum::Singleton.instance
  request = { "jsonrpc": "2.0", "method": "evm_snapshot", "params": [], "id": 1 }.to_json
  return JSON.parse(client.send_single(request))['result']
end

def revert_blockchain(snapshot_id)
  client = Ethereum::Singleton.instance
  request = { "jsonrpc": "2.0", "method": "evm_revert", "params": [snapshot_id], "id": 1 }.to_json
  return JSON.parse(client.send_single(request))['result']
end

def revert_environment_variables
  DreamxApi::Application.load_environment_variables(true)
end

def json
  JSON.parse(response.body).deep_symbolize_keys!
end

def concurrently(thread_count=4)
  waiting = true

  threads = []
  thread_count.times do |i|
    thread = Thread.new do
      true while waiting
      yield(i)
    end
    threads.push(thread)
  end

  waiting = false
  threads.each(&:join)
end

def assert_record_exists(model, records)
  records.each do |record|
    assert_not_nil model.find_by(record)
  end
end

def assert_record_not_exist(model, records)
  records.each do |record|
    assert_nil model.find_by(record)
  end
end

def sign_message(account_address, message)
  key = Eth::Key.new priv: private_keys[account_address]
  return Eth::Utils.prefix_hex(key.personal_sign(Eth::Utils.hex_to_bin(message)))
end

def get_action_nonce
  Time.now.to_i * 1000 + Redis.current.incr('action_nonce')
end

def new_key
  Eth::Key.new
end

def generate_random_transaction_hash
  "0x#{SecureRandom.hex(32)}"
end
