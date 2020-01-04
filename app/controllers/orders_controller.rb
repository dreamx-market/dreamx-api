class OrdersController < ApplicationController
  before_action :check_if_readonly, only: [:create]

  # GET /orders
  def index
    filters = extract_filters_from_query_params([:account_address, :status])
    @orders = Order.where(filters).order(created_at: :desc).paginate(:page => params[:page], :per_page => params[:per_page])
  end

  # POST /orders
  def create
    @order = Order.new(order_params)

    if @order.save
      render :show, status: :created
    else
    	serialize_active_record_validation_error @order.errors.messages
    end
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def order_params
      params.require(:order).permit(:account_address, :give_token_address, :give_amount, :take_token_address, :take_amount, :nonce, :expiry_timestamp_in_milliseconds, :order_hash, :signature)
    end
end
