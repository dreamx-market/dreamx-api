class MarketTickersChannel < ApplicationCable::Channel
  def subscribed
    stop_all_streams
    stream_from "market_tickers:#{params[:market_symbol]}"
  end

  def unsubscribed
    stop_all_streams
  end
end
