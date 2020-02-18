class MarketOrdersChannel < ApplicationCable::Channel
  def subscribed
    stop_all_streams
    if params[:market_symbol]
      stream_from "market_orders:#{params[:market_symbol]}"
    else
      stream_from "market_orders"
    end
  end

  def unsubscribed
    stop_all_streams
  end
end
