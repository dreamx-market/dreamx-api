class MarketsController < ApplicationController
  # GET /markets
  def index
    @markets = Market.paginate({ :page => params[:page], :per_page => params[:per_page] }).includes([:base_token, :quote_token])
  end
end
