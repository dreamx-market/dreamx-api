class AccountsController < ApplicationController
  # GET /accounts/0x8a37b79E54D69e833d79Cac3647C877Ef72830E1
  def show
    @account = Account.find_by(address: params[:address])
  end
end
