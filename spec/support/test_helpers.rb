module TestHelpers
  def sync_nonce
    client = Ethereum::Singleton.instance
    key = Eth::Key.new priv: ENV['SERVER_PRIVATE_KEY'].hex
    Redis.current.set("nonce", client.get_nonce(key.address))
  end

  def hello
    pp 'HELLO WORLD!!!'
  end
end