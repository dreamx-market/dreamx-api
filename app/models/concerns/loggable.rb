module Loggable
  extend ActiveSupport::Concern

  included do
    @@logger ||= Logger.new("#{Rails.root}/log/app.log")

    def log(msg)
      if ENV['RAILS_ENV'] == 'test'
        return
      end

      @@logger.info(msg)
    end
  end
end