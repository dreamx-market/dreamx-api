class AccountBalancesRelayJob < ApplicationJob
  queue_as :default

  def perform(balance)
    locals = { channel: 'AccountBalances', payload: [balance] }
    json = ApplicationController.render('balances/socket', locals: locals)
    ActionCable.server.broadcast("account_balances:#{balance.account_address}", json)
  end
end
