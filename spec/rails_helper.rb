# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'

require File.expand_path('../config/environment', __dir__)

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!

require "action_cable/testing/rspec"

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].each { |f| require f }

# modules included by default for all specs
include TestHelpers

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end
RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  config.include FactoryBot::Syntax::Methods

  # config.global_fixtures = []

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      if Bullet.enable?
        Bullet.start_request
      end

      example.run

      TestHelpers::revert_environment_variables
      Redis.current.flushdb
      Rails.application.load_redis_config_variables

      if Bullet.enable?
        Bullet.end_request
      end
    end
  end

  config.around(:each, :onchain) do |example|
    TestHelpers::sync_nonce
    snapshot_id = TestHelpers::snapshot_blockchain

    example.run

    TestHelpers::revert_blockchain(snapshot_id)
  end

  config.around(:each, :perform_enqueued) do |example|
    old_queue_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
    ActiveJob::Base.queue_adapter.perform_enqueued_at_jobs = true

    example.run

    ActiveJob::Base.queue_adapter = old_queue_adapter
  end

  config.around(:each, :with_funded_accounts) do |example|
    token_address_one = TestHelpers::token_addresses['ETH']
    token_address_two = TestHelpers::token_addresses['ONE']
    token_one = create(:token, address: token_address_one, name: 'Ethereum', symbol: 'ETH')
    token_two = create(:token, address: token_address_two, name: 'One', symbol: 'ONE')

    address_one = TestHelpers::addresses[0]
    address_two = TestHelpers::addresses[1]
    account_one = create(:account, address: address_one)
    account_two = create(:account, address: address_two)
    balance_one = create(:balance, account: account_one, token: token_one, balance: '1000'.to_wei)
    balance_two = create(:balance, account: account_one, token: token_two, balance: '1000'.to_wei)
    balance_three = create(:balance, account: account_two, token: token_one, balance: '1000'.to_wei)
    balance_four = create(:balance, account: account_two, token: token_two, balance: '1000'.to_wei)

    example.run
  end
end
