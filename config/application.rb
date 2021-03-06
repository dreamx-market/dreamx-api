require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
# require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module DreamxApi
  class Application < Rails::Application
    require 'ext/string'
    require 'ext/integer'
    require 'ext/hash'
    require 'config'
    require 'ether_scan'

    def environment_variables
      return {
        GAS_LIMIT: '2000000',
        REDIS_HOST: 'redis://127.0.0.1:6379',
        ETHEREUM_HOST: 'https://ropsten.infura.io/v3/b41fd9db5b3442a5b3be799b1bc91bf0',
        ETHERSCAN_HTTP: 'https://api-ropsten.etherscan.io/api',
        ETHERSCAN_API_KEY: '8QQWQQZEXQT92P9NI6KK67ZCIVPWXJA561',
        CONTRACT_ADDRESS: '0x7e8acb18572ba3979243f5edb11bec45b9c2a9b8',
        MAX_PER_PAGE: '1000',
        MAKER_MINIMUM_ETH_IN_WEI: '150000000000000000', # 0.15 ETH
        TAKER_MINIMUM_ETH_IN_WEI: '50000000000000000', # 0.05 ETH
        MAKER_FEE_PER_ETHER_IN_WEI: '1000000000000000', # 0.1%
        TAKER_FEE_PER_ETHER_IN_WEI: '2000000000000000', # 0.2%
        CHART_DATUM_EXPIRY_5M: 7.days.to_s,
        CHART_DATUM_EXPIRY_15M: 20.days.to_s,
        CHART_DATUM_EXPIRY_1H: 90.days.to_s,
        TRANSACTION_CONFIRMATIONS: '12',
        POSTGRES_USERNAME: 'deploy',
        POSTGRES_PASSWORD: '',
        SECRET_KEY_BASE: 'bff123f6ea48261cf749ba0a27d2cd5e50ffea689aecac9d696d0c47a1d94614e134c427f7fcb9ef2fa6fee05a5b41cfa4f92b21bcf54b4d41a37af7e614b4e6',
        SERVER_PRIVATE_KEY: '0xf1caff04b5ff349674820a4eb6ee11c459ad3698ca581c8a8e82ee09591b7aa2',
        FEE_COLLECTOR_ADDRESS: '0xcc6cfe1a7f27f84309697beeccbc8112a6b7240a',
        LOG_PATH: "#{Rails.root}/log/app.log",
        RATE_LIMIT: '120',
        RATE_LIMIT_DURATION: 1.minute.to_s
      }
    end

    def dev_environment_variables
      return {
        REDIS_HOST: 'redis://127.0.0.1:6379/1' # use database 1 for dev environment
      }
    end

    def test_environment_variables
      return {
        CONTRACT_ADDRESS: '0xf675cf9c811022a8d934df1c96bb8af884dc92ee',
        ETHEREUM_HOST: 'http://localhost:8545',
        TRANSACTION_CONFIRMATIONS: '0',
        REDIS_HOST: 'redis://127.0.0.1:6379/2', # use database 2 for test environment
        ETHERSCAN_HTTP: 'https://api-ropsten.etherscan.io/api',
      }
    end

    def redis_config_variables
      return {
        read_only: 'false',
        processing_new_blocks: 'true'
      }
    end

    def load_redis_config_variables(override = false)
      begin
        config = JSON.parse(Redis.current.get('config'))
      rescue JSON::ParserError, TypeError
        config = {}
      end
      self.redis_config_variables.each do |key, value|
        if (override)
          config[key.to_s] = value.to_s
        else
          config[key.to_s] ||= value.to_s
        end
      end
      Redis.current.set('config', config.to_json)
    end

    def load_environment_variables(override = false)
      self.environment_variables.each do |key, value|
        if override
          ENV[key.to_s] = value.to_s
        else
          ENV[key.to_s] ||= value.to_s
        end
      end

      if ENV['RAILS_ENV'] == 'development'
        self.dev_environment_variables.each do |key, value|
          ENV[key.to_s] = value.to_s
        end
      end

      if ENV['RAILS_ENV'] == 'test'
        self.test_environment_variables.each do |key, value|
          ENV[key.to_s] = value.to_s
        end
      end
    end

    self.load_environment_variables
    self.load_redis_config_variables

  	config.eager_load_paths << Rails.root.join('lib')
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # pagination
    WillPaginate.per_page = 100

    config.action_cable.disable_request_forgery_protection = true

    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
