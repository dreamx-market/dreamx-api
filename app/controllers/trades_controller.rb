class TradesController < ApplicationController
  before_action :set_trade, only: [:show, :update, :destroy]

  # # GET /trades
  # # GET /trades.json
  # def index
  #   @trades = Trade.all
  # end

  # # GET /trades/1
  # # GET /trades/1.json
  # def show
  # end

  # POST /trades
  # POST /trades.json
  def create
    @trade = Trade.new(trade_params)

    if @trade.save
      render :show, status: :created, location: @trade
    else
      render json: @trade.errors, status: :unprocessable_entity
    end
  end

  # # PATCH/PUT /trades/1
  # # PATCH/PUT /trades/1.json
  # def update
  #   if @trade.update(trade_params)
  #     render :show, status: :ok, location: @trade
  #   else
  #     render json: @trade.errors, status: :unprocessable_entity
  #   end
  # end

  # # DELETE /trades/1
  # # DELETE /trades/1.json
  # def destroy
  #   @trade.destroy
  # end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_trade
      @trade = Trade.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def trade_params
      params.require(:trade).permit(:account_address, :order_hash, :amount, :nonce, :trade_hash, :signature, :uuid)
    end
end
