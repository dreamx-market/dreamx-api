class OrdersController < ApplicationController
  # before_action :set_order, only: [:show, :update, :destroy]

  # # GET /orders
  # # GET /orders.json
  # def index
  #   @orders = Order.all
  # end

  # # GET /orders/1
  # # GET /orders/1.json
  # def show
  # end

  # POST /orders
  # POST /orders.json
  def create
    @order = Order.new(order_params)

    if @order.save
      render :show, status: :created, location: @order
    else
    	errors = []
    	@order.errors.messages.each do |key, array|
    		errors << { :field => key, :reason => array }
    	end
    	raise Error::ValidationError.new(errors)
    end
  end

  # # PATCH/PUT /orders/1
  # # PATCH/PUT /orders/1.json
  # def update
  #   if @order.update(order_params)
  #     render :show, status: :ok, location: @order
  #   else
  #     render json: @order.errors, status: :unprocessable_entity
  #   end
  # end

  # # DELETE /orders/1
  # # DELETE /orders/1.json
  # def destroy
  #   @order.destroy
  # end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_order
      @order = Order.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def order_params
      params.require(:order).permit(:account_address, :give_token_address, :give_amount, :take_token_address, :take_amount, :nonce, :expiry_timestamp_in_milliseconds, :order_hash, :signature)
    end
end
