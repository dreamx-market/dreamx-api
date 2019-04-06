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

module NinjatradeApi
  class Application < Rails::Application
    require 'ext/string'
  	require 'ext/integer'
  	
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

    # environment variables, can be overridden
    ENV['SECRET_KEY_BASE'] = ENV['SECRET_KEY_BASE'] || ''
    ENV['POSTGRES_PASSWORD'] = ENV['POSTGRES_PASSWORD'] || ''
    ENV['GAS_LIMIT'] = ENV['GAS_LIMIT'] || '2000000'
    ENV['REDIS_HOST'] = ENV['REDIS_HOST'] || 'redis://127.0.0.1:6379'
    ENV['PRIVATE_KEY'] = ENV['PRIVATE_KEY'] || '0xf1caff04b5ff349674820a4eb6ee11c459ad3698ca581c8a8e82ee09591b7aa2'
    ENV['ETHEREUM_HOST'] = ENV['ETHEREUM_HOST'] || 'https://ropsten.infura.io/v3/b41fd9db5b3442a5b3be799b1bc91bf0'
    ENV['CONTRACT_ADDRESS'] = ENV['CONTRACT_ADDRESS'] || '0xf06abaa2ff45cd469c2dab6ad9f8848ce12850d1'
    ENV['MAX_PER_PAGE'] = ENV['MAX_PER_PAGE'] || '1000'
    ENV['MAKER_MINIMUM_ETH_IN_WEI'] = ENV['MAKER_MINIMUM_ETH_IN_WEI'] || '150000000000000000'
    ENV['TAKER_MINIMUM_ETH_IN_WEI'] = ENV['TAKER_MINIMUM_ETH_IN_WEI'] || '50000000000000000'
    ENV['MAKER_FEE_PER_ETHER_IN_WEI'] = ENV['MAKER_FEE_PER_ETHER_IN_WEI'] || '1000000000000000' # 0.001 per Ether
    ENV['TAKER_FEE_PER_ETHER_IN_WEI'] = ENV['TAKER_FEE_PER_ETHER_IN_WEI'] || '2000000000000000' # 0.002 per Ether
    ENV['FEE_COLLECTOR_ADDRESS'] = ENV['FEE_COLLECTOR_ADDRESS'] || '0xcc6cfe1a7f27f84309697beeccbc8112a6b7240a'
    ENV['READONLY'] = ENV['READONLY'] || 'false'
    ENV['CHART_DATUM_EXPIRY_5M'] = ENV['CHART_DATUM_EXPIRY_5M'] || 7.days.to_s
    ENV['CHART_DATUM_EXPIRY_15M'] = ENV['CHART_DATUM_EXPIRY_15M'] || 20.days.to_s
    ENV['CHART_DATUM_EXPIRY_1H'] = ENV['CHART_DATUM_EXPIRY_1H'] || 90.days.to_s
    ENV['TRANSACTION_CONFIRMATIONS'] = ENV['TRANSACTION_CONFIRMATIONS'] || '12'
    ENV['POSTPONE_BROADCASTING'] = ENV['POSTPONE_BROADCASTING'] || 'false'
  end
end
