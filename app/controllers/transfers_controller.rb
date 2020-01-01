class TransfersController < ApplicationController
  before_action :set_transfer, only: [:show]

  # GET /transfers/1
  def show
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_transfer
      @transfers = Transfer.find_transfers(params)
    end
end
