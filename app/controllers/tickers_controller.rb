class TickersController < ApplicationController
  before_action :set_ticker, only: [:show, :update, :destroy]

  # GET /tickers
  # GET /tickers.json
  def index
    @tickers = Ticker.paginate :page => params[:page], :per_page => params[:per_page]
  end

  # GET /tickers/1
  # GET /tickers/1.json
  def show
  end

  # # POST /tickers
  # # POST /tickers.json
  # def create
  #   @ticker = Ticker.new(ticker_params)

  #   if @ticker.save
  #     render :show, status: :created, location: @ticker
  #   else
  #     render json: @ticker.errors, status: :unprocessable_entity
  #   end
  # end

  # # PATCH/PUT /tickers/1
  # # PATCH/PUT /tickers/1.json
  # def update
  #   if @ticker.update(ticker_params)
  #     render :show, status: :ok, location: @ticker
  #   else
  #     render json: @ticker.errors, status: :unprocessable_entity
  #   end
  # end

  # # DELETE /tickers/1
  # # DELETE /tickers/1.json
  # def destroy
  #   @ticker.destroy
  # end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ticker
      @ticker = Ticker.find_by({ :market_symbol => params[:market_symbol] })
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def ticker_params
      params.fetch(:ticker, {})
    end
end
