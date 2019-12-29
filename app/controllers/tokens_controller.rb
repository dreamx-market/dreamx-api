class TokensController < ApplicationController
  # GET /tokens
  def index
    @tokens = Token.paginate :page => params[:page], :per_page => params[:per_page]
  end
end
