class TickersController < ApplicationController
  before_action :set_ticker, only: [:show]

  # GET /tickers
  def index
    @tickers = Ticker.paginate :page => params[:page], :per_page => params[:per_page]
  end

  # GET /tickers/1
  def show
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_ticker
    @ticker = Ticker.find_by!({ :market_symbol => params[:market_symbol] })
  end
end
