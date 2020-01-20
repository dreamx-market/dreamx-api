class TransfersController < ApplicationController
  # GET /transfers/1
  def show
    account = Account.find_by(address: params[:account_address])

    if account
      from = params[:start]
      to = params[:end]
      page = params[:page]
      per_page = params[:per_page]
      @transfers = account.transfers_within_period(from, to, page, per_page)
    else
      @transfers = { deposits: [], withdraws: [] }
    end
  end
end
