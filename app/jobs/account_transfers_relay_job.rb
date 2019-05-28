class AccountTransfersRelayJob < ApplicationJob
  queue_as :default

  def perform(transfer)
    locals = { channel: 'AccountTransfers', payload: [transfer] }
    json = JSON.parse(ApplicationController.render('transfers/socket', locals: locals))
    ActionCable.server.broadcast("account_transfers:#{transfer.account_address}", json)
  end
end
