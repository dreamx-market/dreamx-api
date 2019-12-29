class OrderBooksController < ApplicationController
  before_action :set_order_book, only: [:show]

  # GET /order_books/1
  def show
    if !@order_book
      head :not_found
      return
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_order_book
      @order_book = OrderBook.find_by_market_symbol(params[:market_symbol], params[:page], params[:per_page])
    end
end
