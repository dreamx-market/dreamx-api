class OrderCancelsController < ApplicationController
  before_action :check_if_readonly, only: [:create]
  before_action :set_order_cancel, only: [:show, :update, :destroy]

  # # GET /order_cancels
  # # GET /order_cancels.json
  # def index
  #   @order_cancels = OrderCancel.all
  # end

  # # GET /order_cancels/1
  # # GET /order_cancels/1.json
  # def show
  # end

  # POST /order_cancels
  # POST /order_cancels.json
  def create
    @order_cancels = []

    begin
      order_cancels_params.each do |order_cancel_param|
        order_cancel = OrderCancel.create!(order_cancel_param)
        @order_cancels.push(order_cancel)
      end
      render :show, status: :created
    rescue
      render json: "failed to create, please check your payload", status: :unprocessable_entity
    end
  end

  # # PATCH/PUT /order_cancels/1
  # # PATCH/PUT /order_cancels/1.json
  # def update
  #   if @order_cancel.update(order_cancel_params)
  #     render :show, status: :ok, location: @order_cancel
  #   else
  #     render json: @order_cancel.errors, status: :unprocessable_entity
  #   end
  # end

  # # DELETE /order_cancels/1
  # # DELETE /order_cancels/1.json
  # def destroy
  #   @order_cancel.destroy
  # end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_order_cancel
      @order_cancel = OrderCancel.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def order_cancels_params
      params.require('_json').map do |p|
        p.permit(:order_hash, :account_address, :nonce, :cancel_hash, :signature)
      end
    end
end
