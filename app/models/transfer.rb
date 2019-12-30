class Transfer < ApplicationRecord
  def self.find_transfers(params)
    account = Account.find_by!({ :address => params[:account_address] })
    from = params[:start] ? Time.at(params[:start].to_i) : Time.at(0)
    to = params[:end] ? Time.at(params[:end].to_i) : Time.current
    deposits = account.deposits.order('deposits.created_at DESC').where({ :created_at => from..to })
    withdraws = account.withdraws.order('withdraws.created_at DESC').where({ :created_at => from..to })
    transfers = (deposits | withdraws).paginate(:page => params[:page], :per_page => params[:per_page])
    return transfers
  end
end
