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
      :"0xcc6cfe1a7f27f84309697beeccbc8112a6b7240a" => 0xa936c57c1e46cec1f70a336c32ecc751bc465070da3fe556d526a082542cc177,
      :"0x76446f63C6B7756257B9c7D56cE7dDe29836c203" => 0x2b615c2e8ab0fa8ec8c711b5c20c7715d5bb823a40398db9df46f994ab5d53e2
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

  # deposits [ { :account_address, :token_address, :amount }, ... ]
  def batch_deposit(deposits)
    created = []
    created_txs = []

    deposits.each do |deposit|
      new_tx = rand(1000..9999)
      while created_txs.include? new_tx
        new_tx = rand(1000..9999)
      end
      created_txs << new_tx

      deposit[:transaction_hash] = new_tx

      created << Deposit.create(deposit)
    end

    return created
  end

  # orders [ { :account_address, :give_token_address, :give_amount, :take_token_address, :take_amount }, ... ]
  def batch_order(orders)
    created = []
    orders.each do |order|
      created << Order.create(generate_order(order))
    end
    return created
  end

  # trades [ { :account_address, :order_hash, :amount }, ... ]
  def batch_trade(trades)
    created = []
    trades.each do |trade|
      created << Trade.create(generate_trade(trade))
    end
    return created
  end

  # withdraws [ { :account_address, :token_address, :amount }, ... ]
  def batch_withdraw(withdraws)
    created = []
    withdraws.each do |withdraw|
      created << Withdraw.create(generate_withdraw(withdraw))
    end
    return created
  end

  # params { :account_address, :token_address, :amount }
  def generate_withdraw(params)
    withdraw = { 
      :account_address => params[:account_address], 
      :token_address => params[:token_address], 
      :amount => params[:amount],
      :nonce => Withdraw.last ? Withdraw.last.nonce.to_i + 1 : (Time.now.to_i * 1000).to_s,
    }
    withdraw[:withdraw_hash] = Withdraw.calculate_hash(withdraw)
    withdraw[:signature] = sign_message(withdraw[:account_address], withdraw[:withdraw_hash])
    return withdraw
  end

  # params { :account_address, :give_token_address, :give_amount, :take_token_address, :take_amount }
  def generate_order(params)
    order = { 
      :account_address => params[:account_address], 
      :give_token_address => params[:give_token_address], 
      :give_amount => params[:give_amount], 
      :take_token_address => params[:take_token_address], 
      :take_amount => params[:take_amount],
      :nonce => Order.last ? Order.last.nonce.to_i + 1 : (Time.now.to_i * 1000).to_s,
      :expiry_timestamp_in_milliseconds => (7.days.from_now.to_i * 1000).to_s
    }
    order[:order_hash] = Order.calculate_hash(order)
    order[:signature] = sign_message(order[:account_address], order[:order_hash])
    return order
  end

  # params { :order_hash, :account_address }
  def generate_order_cancel(params)
    order_cancel = {
      :order_hash => params[:order_hash],
      :account_address => params[:account_address],
      :nonce => OrderCancel.last ? OrderCancel.last.nonce.to_i + 1 : (Time.now.to_i * 1000).to_s,
    }
    order_cancel[:cancel_hash] = OrderCancel.calculate_hash(order_cancel)
    order_cancel[:signature] = sign_message(order_cancel[:account_address], order_cancel[:cancel_hash])
    return order_cancel
  end

  # params { :account_address, :order_hash, :amount }
  def generate_trade(params)
    trade = {
      :account_address => params[:account_address],
      :order_hash => params[:order_hash],
      :amount => params[:amount],
      :nonce => Trade.last ? Trade.last.nonce.to_i + 1 : (Time.now.to_i * 1000).to_s,
    }
    trade[:trade_hash] = Trade.calculate_hash(trade)
    trade[:signature] = sign_message(trade[:account_address], trade[:trade_hash])
    return trade
  end

  def sign_message(account_address, message)
    key = Eth::Key.new priv: accounts[:"#{account_address}"]
    return Eth::Utils.prefix_hex(key.personal_sign(Eth::Utils.hex_to_bin(message)))
  end
end
