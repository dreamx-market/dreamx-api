class ActiveSupport::TestCase
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
      new_order = Order.new(generate_order(order))

      # TO BE REMOVED
      if new_order.valid?
        assert new_order.save
      else
        p new_order.errors.messages
        byebug
      end

      created << new_order
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
      new_withdraw = Withdraw.new(generate_withdraw(withdraw))
      assert new_withdraw.save
      created << new_withdraw
    end
    return created
  end

  # params { :account_address, :token_address, :amount }
  def generate_withdraw(params)
    withdraw = { 
      :account_address => params[:account_address], 
      :token_address => params[:token_address], 
      :amount => params[:amount],
      :nonce => get_action_nonce,
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
      :nonce => get_action_nonce,
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
      :nonce => get_action_nonce,
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
      :nonce => get_action_nonce,
    }
    trade[:trade_hash] = Trade.calculate_hash(trade)
    trade[:signature] = sign_message(trade[:account_address], trade[:trade_hash])
    return trade
  end
end
