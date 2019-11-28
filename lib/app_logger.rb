class AppLogger
  class << self
    def log(msg)
      @@logger ||= Logger.new(ENV['LOG_PATH'])
      @@logger.info(msg)
    end
  end
end