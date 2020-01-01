class OrderBooksController < ApplicationController
  # GET /order_books/1
  def show
    market = Market.find_by!({ symbol: params[:market_symbol] })
    @order_book = market.order_book(params[:page], params[:per_page])
  end
end
