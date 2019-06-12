class Config
  class << self
    def get
      config = Redis.current.get('config')
      JSON.parse(config)
    end

    def set(key, value)
      config = self.get
      config[key] = value
      Redis.current.set('config', config.to_json)
    end
  end
end