class OrderCancelsController < ApplicationController
  before_action :check_if_readonly, only: [:create]

  # POST /order_cancels
  def create
    begin
      @order_cancels = []
      ActiveRecord::Base.transaction do
        order_cancels_params.each do |order_cancel_param|
          order_cancel = OrderCancel.create!(order_cancel_param)
          @order_cancels.push(order_cancel)
        end
      end
      render :show, status: :created
    rescue ActiveRecord::RecordInvalid
      order_cancels_errors = []
      order_cancels_params.each do |order_cancel_param|
        order_cancel = OrderCancel.new(order_cancel_param)
        order_cancel.valid?
        order_cancels_errors.push(order_cancel.errors.messages)
      end
      serialize_active_record_validation_error order_cancels_errors
    end
  end


  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def order_cancels_params
      params.require('_json').map do |p|
        p.permit(:order_hash, :account_address, :nonce, :cancel_hash, :signature)
      end
    end
end
