class BalancesController < ApplicationController
  before_action :set_balance, only: [:show, :update, :destroy]

  # # GET /balances
  # # GET /balances.json
  # def index
  #   @balances = Balance.all
  # end

  # GET /balances/1
  # GET /balances/1.json
  def show
  end

  # # POST /balances
  # # POST /balances.json
  # def create
  #   @balance = Balance.new(balance_params)

  #   if @balance.save
  #     render :show, status: :created, location: @balance
  #   else
  #     render json: @balance.errors, status: :unprocessable_entity
  #   end
  # end

  # # PATCH/PUT /balances/1
  # # PATCH/PUT /balances/1.json
  # def update
  #   if @balance.update(balance_params)
  #     render :show, status: :ok, location: @balance
  #   else
  #     render json: @balance.errors, status: :unprocessable_entity
  #   end
  # end

  # # DELETE /balances/1
  # # DELETE /balances/1.json
  # def destroy
  #   @balance.destroy
  # end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_balance
      @balance = Balance.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def balance_params
      params.require(:balance).permit(:account, :token, :balance, :integer, :holdBalance)
    end
end
