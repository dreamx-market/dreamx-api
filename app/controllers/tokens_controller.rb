class TokensController < ApplicationController
  before_action :set_token, only: [:show, :update, :destroy]
  before_action :validate_pagination_params, only: [:index]

  # GET /tokens
  # GET /tokens.json
  def index
    @tokens = Token.paginate :page => params[:page], :per_page => params[:per_page]
  end

  # GET /tokens/1
  # GET /tokens/1.json
  def show
  end

  # POST /tokens
  # POST /tokens.json
  def create
    @token = Token.new(token_params)

    if @token.save
      render :show, status: :created, location: @token
    else
      render json: @token.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /tokens/1
  # PATCH/PUT /tokens/1.json
  def update
    if @token.update(token_params)
      render :show, status: :ok, location: @token
    else
      render json: @token.errors, status: :unprocessable_entity
    end
  end

  # DELETE /tokens/1
  # DELETE /tokens/1.json
  def destroy
    @token.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_token
      @token = Token.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def token_params
      params.require(:token).permit(:name, :address, :symbol, :decimals)
    end
end
