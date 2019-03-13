class Transfer < ApplicationRecord
  def self.find_transfer(params)
    @account ||= Account.find_by({ :address => params[:account_address] })
    deposits = @account.deposits.order('deposits.created_at DESC').paginate(:page => params[:page], :per_page => params[:per_page])
    withdraws = @account.withdraws.order('withdraws.created_at DESC').paginate(:page => params[:page], :per_page => params[:per_page])
    transfer = { :deposits => deposits, :withdraws => withdraws }
    return transfer
  end
end
