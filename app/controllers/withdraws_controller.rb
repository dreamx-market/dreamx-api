class WithdrawsController < ApplicationController
  before_action :set_withdraw, only: [:show, :update, :destroy]

  # # GET /withdraws
  # # GET /withdraws.json
  # def index
  #   @withdraws = Withdraw.all
  # end

  # # GET /withdraws/1
  # # GET /withdraws/1.json
  # def show
  # end

  # POST /withdraws
  # POST /withdraws.json
  def create
    @withdraw = Withdraw.new(withdraw_params)

    if @withdraw.save
      render :show, status: :created, location: @withdraw
    else
      render json: @withdraw.errors, status: :unprocessable_entity
    end
  end

  # # PATCH/PUT /withdraws/1
  # # PATCH/PUT /withdraws/1.json
  # def update
  #   if @withdraw.update(withdraw_params)
  #     render :show, status: :ok, location: @withdraw
  #   else
  #     render json: @withdraw.errors, status: :unprocessable_entity
  #   end
  # end

  # # DELETE /withdraws/1
  # # DELETE /withdraws/1.json
  # def destroy
  #   @withdraw.destroy
  # end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_withdraw
      @withdraw = Withdraw.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def withdraw_params
      params.require(:withdraw).permit(:account_address, :amount, :token_address, :nonce, :withdraw_hash, :signature)
    end
end
