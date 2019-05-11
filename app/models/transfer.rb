class Transfer < ApplicationRecord
  def self.find_transfer(params)
    account = Account.find_by!({ :address => params[:account_address] })

    start_timestamp = params[:start] || 0
    end_timestamp = params[:end] || Time.current
    deposits = account.deposits.order('deposits.created_at DESC').where({ :created_at => Time.zone.at(start_timestamp.to_i)..Time.zone.at(end_timestamp.to_i) }).paginate(:page => params[:page], :per_page => params[:per_page])
    withdraws = account.withdraws.order('withdraws.created_at DESC').where({ :created_at => Time.zone.at(start_timestamp.to_i)..Time.zone.at(end_timestamp.to_i) }).paginate(:page => params[:page], :per_page => params[:per_page])

    transfer = { :deposits => deposits, :withdraws => withdraws }
    return transfer
  end
end
