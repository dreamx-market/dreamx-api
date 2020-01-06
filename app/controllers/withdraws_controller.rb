class WithdrawsController < ApplicationController
  before_action :check_if_readonly, only: [:create]

  # POST /withdraws
  def create
    @withdraw = Withdraw.new(withdraw_params)

    begin
      ActiveRecord::Base.transaction do
        @withdraw.save!
      end
      render :show, status: :created
    rescue ActiveRecord::RecordInvalid
      serialize_active_record_validation_error @withdraw.errors.messages
    end
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def withdraw_params
      params.require(:withdraw).permit(:account_address, :amount, :token_address, :nonce, :withdraw_hash, :signature)
    end
end
