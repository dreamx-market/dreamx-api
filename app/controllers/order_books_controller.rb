class OrderBooksController < ApplicationController
  before_action :set_order_book, only: [:show, :update, :destroy]

  # # GET /order_books
  # # GET /order_books.json
  # def index
  #   @order_books = OrderBook.all
  # end

  # GET /order_books/1
  # GET /order_books/1.json
  def show
  end

  # # POST /order_books
  # # POST /order_books.json
  # def create
  #   @order_book = OrderBook.new(order_book_params)

  #   if @order_book.save
  #     render :show, status: :created, location: @order_book
  #   else
  #     render json: @order_book.errors, status: :unprocessable_entity
  #   end
  # end

  # # PATCH/PUT /order_books/1
  # # PATCH/PUT /order_books/1.json
  # def update
  #   if @order_book.update(order_book_params)
  #     render :show, status: :ok, location: @order_book
  #   else
  #     render json: @order_book.errors, status: :unprocessable_entity
  #   end
  # end

  # # DELETE /order_books/1
  # # DELETE /order_books/1.json
  # def destroy
  #   @order_book.destroy
  # end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_order_book
      @order_book = OrderBook.find_by_symbol(params[:symbol], params[:page], params[:per_page])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def order_book_params
      params.fetch(:order_book, {})
    end
end
