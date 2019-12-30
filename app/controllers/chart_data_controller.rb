class ChartDataController < ApplicationController
  before_action :set_chart_datum, only: [:show, :update, :destroy]

  # GET /chart_data/1
  def show
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_chart_datum
    from = params[:start] ? Time.at(params[:start].to_i) : 7.days.ago
    to = params[:end] ? Time.at(params[:end].to_i) : Time.current
    period = params[:period] || 1.hour.to_i
    @chart_data = ChartDatum.where({ :market_symbol => params[:market_symbol], :period => period, :created_at => from..to }).order(:created_at)
  end
end
