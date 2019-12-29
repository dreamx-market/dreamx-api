class TradesController < ApplicationController
  before_action :check_if_readonly, only: [:create]
  before_action :set_trade, only: [:show, :update, :destroy]

  # GET /trades
  # GET /trades.json
  def index
    start_timestamp = params[:start] || 0
    end_timestamp = params[:end] || Time.current + 1.second # + 1 second to include trades created at this exact moment
    filters = extract_filters_from_query_params([:account_address, :market_symbol])

    if filters.empty?
      @trades = Trade.where({ :created_at => Time.zone.at(start_timestamp.to_i)..Time.zone.at(end_timestamp.to_i) })
                .includes([:order, :tx])
                .order(created_at: :desc)
                .paginate(:page => params[:page], :per_page => params[:per_page])
    else
      @trades = Trade.joins(:order).where({ :trades => filters, :created_at => Time.zone.at(start_timestamp.to_i)..Time.zone.at(end_timestamp.to_i) })
                .or(Trade.joins(:order).where({ :orders => filters, :created_at => Time.zone.at(start_timestamp.to_i)..Time.zone.at(end_timestamp.to_i) }))
                .includes([:order, :tx])
                .order(created_at: :desc)
                .paginate(:page => params[:page], :per_page => params[:per_page])
    end
  end

  # GET /trades/1
  # GET /trades/1.json
  def show
  end

  # POST /trades
  # POST /trades.json
  def create
    begin
      @trades = []
      ActiveRecord::Base.transaction do
        trades_params.each do |trade_param|
          @trades.push(Trade.create!(trade_param))
        end
      end
      render :show, status: :created
    rescue ActiveRecord::RecordInvalid
      trades_errors = []
      trades_params.each do |trade_param|
        trade = Trade.new(trade_param)
        trade.valid?
        trades_errors.push(trade.errors.messages)
      end
      serialize_active_record_validation_error trades_errors
    end
  end

  # # PATCH/PUT /trades/1
  # # PATCH/PUT /trades/1.json
  # def update
  #   if @trade.update(trade_params)
  #     render :show, status: :ok, location: @trade
  #   else
  #     render json: @trade.errors, status: :unprocessable_entity
  #   end
  # end

  # # DELETE /trades/1
  # # DELETE /trades/1.json
  # def destroy
  #   @trade.destroy
  # end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_trade
      @trade = Trade.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def trades_params
      params.require('_json').map do |p|
        p.permit(:account_address, :order_hash, :amount, :nonce, :trade_hash, :signature)
      end
    end
end
