class ChartDataController < ApplicationController
  before_action :set_chart_datum, only: [:show, :update, :destroy]

  # # GET /chart_data
  # # GET /chart_data.json
  # def index
  #   @chart_data = ChartDatum.all
  # end

  # GET /chart_data/1
  # GET /chart_data/1.json
  def show
  end

  # # POST /chart_data
  # # POST /chart_data.json
  # def create
  #   @chart_datum = ChartDatum.new(chart_datum_params)

  #   if @chart_datum.save
  #     render :show, status: :created, location: @chart_datum
  #   else
  #     render json: @chart_datum.errors, status: :unprocessable_entity
  #   end
  # end

  # # PATCH/PUT /chart_data/1
  # # PATCH/PUT /chart_data/1.json
  # def update
  #   if @chart_datum.update(chart_datum_params)
  #     render :show, status: :ok, location: @chart_datum
  #   else
  #     render json: @chart_datum.errors, status: :unprocessable_entity
  #   end
  # end

  # # DELETE /chart_data/1
  # # DELETE /chart_data/1.json
  # def destroy
  #   @chart_datum.destroy
  # end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_chart_datum
      start_timestamp = params[:start] || 7.days.ago
      end_timestamp = params[:end] || Time.current
      period = params[:period] || 1.hour.to_i
      @chart_data = ChartDatum.where({ :market_symbol => params[:market_symbol], :period => period, :created_at => Time.zone.at(start_timestamp.to_i)..Time.zone.at(end_timestamp.to_i) }).order(:created_at)
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def chart_datum_params
      params.require(:chart_datum).permit(:high, :low, :open, :close, :volume, :quote_volume, :average, :period)
    end
end
