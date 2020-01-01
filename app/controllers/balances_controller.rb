class BalancesController < ApplicationController
  before_action :set_balance, only: [:show]

  # GET /balances/0x8a37b79E54D69e833d79Cac3647C877Ef72830E1
  def show
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_balance
      @balances = Balance.where(account_address: params[:account_address]).paginate(:page => params[:page], :per_page => params[:per_page])
    end
end
