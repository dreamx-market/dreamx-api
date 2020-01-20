class TransfersController < ApplicationController
  # GET /transfers/1
  def show
    account = Account.find_by(address: params[:account_address])
    page = params[:page]
    per_page = params[:per_page]

    if account
      from = params[:start]
      to = params[:end]
      @transfers = account.transfers_within_period(from, to, page, per_page)
    else
      @transfers = { 
        deposits: [].paginate(page: page, per_page: per_page), # transfers#show expects paginated collections
        withdraws: [].paginate(page: page, per_page: per_page) 
      }
    end
  end
end
