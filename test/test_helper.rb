ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
  def json
  	JSON.parse(response.body)
  end

  def assert_model(model, records)
    records.each do |record|
      assert_not_nil model.find_by(record)
    end
  end

  def assert_model_nil(model, records)
    records.each do |record|
      assert_nil model.find_by(record)
    end
  end
end
