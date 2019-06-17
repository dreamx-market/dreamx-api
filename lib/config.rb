class Config
  class << self
    def get(key)
      begin
        config = JSON.parse(Redis.current.get('config'))
      rescue JSON::ParserError, TypeError
        config = {}
      end
      return config[key]
    end

    def set(key, value)
      begin
        config = JSON.parse(Redis.current.get('config'))
      rescue JSON::ParserError, TypeError
        config = {}
      end
      config[key] = value
      Redis.current.set('config', config.to_json)
    end
  end
end