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

  def uncreate_order(order)
    remaining = order.give_amount.to_i - order.filled.to_i
    balance = Balance.find_by(:account_address => order.account_address, :token_address => order.give_token_address)
    balance.release(remaining)
    order.destroy!
  end

  def batch_deposit(deposits)
    deposits.each do |deposit|
      Deposit.create(deposit)
    end
  end
end
