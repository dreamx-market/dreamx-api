class MarketChartDataChannel < ApplicationCable::Channel
  def subscribed
    stop_all_streams
    stream_from "market_chart_data:#{params[:market_symbol]}:#{params[:period]}"
  end

  def unsubscribed
    stop_all_streams
  end
end
