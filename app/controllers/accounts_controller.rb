class AccountsController < ApplicationController
  # before_action :set_account, only: [:show, :update, :destroy]

  # # GET /accounts
  # # GET /accounts.json
  # def index
  #   @accounts = Account.all
  # end

  # # GET /accounts/0x8a37b79E54D69e833d79Cac3647C877Ef72830E1
  # def show
  # 	@balances = @account.balances.paginate(:page => params[:page], :per_page => params[:per_page])
  # end

  # # POST /accounts
  # # POST /accounts.json
  # def create
  #   @account = Account.new(account_params)

  #   if @account.save
  #     render :show, status: :created, location: @account
  #   else
  #     render json: @account.errors, status: :unprocessable_entity
  #   end
  # end

  # # PATCH/PUT /accounts/1
  # # PATCH/PUT /accounts/1.json
  # def update
  #   if @account.update(account_params)
  #     render :show, status: :ok, location: @account
  #   else
  #     render json: @account.errors, status: :unprocessable_entity
  #   end
  # end

  # # DELETE /accounts/1
  # # DELETE /accounts/1.json
  # def destroy
  #   @account.destroy
  # end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_account
      @account = Account.find_by(address: params[:address])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def account_params
      params.fetch(:account, {})
    end
end
