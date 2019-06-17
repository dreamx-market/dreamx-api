class Config
  class << self
    def get
      begin
        config = Redis.current.get('config')
        return JSON.parse(config)
      rescue JSON::ParserError, TypeError
        return {}
      end
    end

    def set(key, value)
      config = self.get
      config[key] = value
      Redis.current.set('config', config.to_json)
    end
  end
end