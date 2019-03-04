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

  def accounts
    {
      :"0xe37a4faa73fced0a177da51d8b62d02764f2fc45" => 0xd15b17f51f613d0d89c64c7b629ffff7ae9c19e509afc9518dac1650e9812c18,
      :"0xa77344043e0b0bada9318f41803e07e9dfc57b0b" => 0xf1caff04b5ff349674820a4eb6ee11c459ad3698ca581c8a8e82ee09591b7aa2,
      :"0xbfd525710ecb49a266337683971bac0d72d746a6" => 0x24b39c598f81d10af245a6b0c1733be41b63ce4d7ea2e694535a2d1c3730c7b9,
      :"0xfa46ed8f8d3f15e7d820e7246233bbd9450903e3" => 0x481118f6ea0f477469c7040fdb5fda6d9e2b32a5eea79b68256a20498815ba34,
      :"0x266a483b876c85fb10c1bd0933e3e64e7ce4ecbb" => 0xf67a9579d888aee21c9ecfb7e9bfbb03940f4e20ee34bab2a3e3aa0c3832bff3,
      :"0x16e86d3935e8922a9b14c722a97552a202575256" => 0xa23c19df2d411241cd5f6fdef64333e43475c7ee1fb626dd9c956284fd8ceca0,
      :"0x9a94af493513afc3873c5b6eced09874f0a6f751" => 0x6ffbd5ff2ac4762f0d3e06ed3e253441ff9802bd9fab89bcc0996a5fb737e460,
      :"0xae5e918b65623660701586ca187c9485c03334bb" => 0xdb3e755d28ee954bdff322be697ba57dd797b6aa8e0dd4ef1edc52ae280e79e9,
      :"0xf06abaa2ff45cd469c2dab6ad9f8848ce12850d1" => 0xb2be1b7f9e3bb42b30d200623a03fc9dbbf840802567073250e3b6fdff6d3f6e,
      :"0xcc6cfe1a7f27f84309697beeccbc8112a6b7240a" => 0xa936c57c1e46cec1f70a336c32ecc751bc465070da3fe556d526a082542cc177
    }
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

  def generate_withdraw(params)
    withdraw = params

    encoder = Ethereum::Encoder.new

    withdraw[:nonce] = (Time.now.to_i * 1000).to_s

    encoded_amount = encoder.encode("uint", withdraw[:amount].to_i)
    encoded_nonce = encoder.encode("uint", withdraw[:nonce].to_i)
    payload = ENV['CONTRACT_ADDRESS'] + withdraw[:account_address].without_prefix + withdraw[:token_address].without_prefix + encoded_amount + encoded_nonce
    withdraw[:withdraw_hash] = Eth::Utils.bin_to_prefixed_hex(Eth::Utils.keccak256(Eth::Utils.hex_to_bin(payload)))

    key = Eth::Key.new priv: accounts[:"#{withdraw[:account_address]}"]
    withdraw[:signature] = Eth::Utils.prefix_hex(key.personal_sign(Eth::Utils.hex_to_bin(withdraw[:withdraw_hash])))

    return withdraw
  end
end
