class TradesController < ApplicationController
  before_action :check_if_readonly, only: [:create]

  # GET /trades
  def index
    from = params[:start] ? Time.at(params[:start].to_i) : Time.at(0)
    to = params[:end] ? Time.at(params[:end].to_i) : Time.current + 1.second # + 1 second to include trades created at this exact moment
    filters = extract_filters_from_query_params([:account_address, :market_symbol])

    if filters.empty?
      @trades = Trade.where({ :created_at => from..to })
                .includes([:order, :tx])
                .order(created_at: :desc)
                .paginate(:page => params[:page], :per_page => params[:per_page])
    else
      @trades = Trade.joins(:order).where({ :trades => filters, :created_at => from..to })
                .or(Trade.joins(:order).where({ :orders => filters, :created_at => from..to }))
                .includes([:order, :tx])
                .order(created_at: :desc)
                .paginate(:page => params[:page], :per_page => params[:per_page])
    end
  end

  # POST /trades
  def create
    begin
      @trades = []
      ActiveRecord::Base.transaction do
        trades_params.each do |trade_param|
          @trades.push(Trade.create!(trade_param))
        end
      end
      render :show, status: :created
    rescue ActiveRecord::RecordInvalid => invalid
      serialize_active_record_validation_error invalid.record.errors.messages
    end
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def trades_params
      params.require('_json').map do |p|
        p.permit(:account_address, :order_hash, :amount, :nonce, :trade_hash, :signature)
      end
    end
end
