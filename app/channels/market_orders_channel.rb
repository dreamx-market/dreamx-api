class MarketOrdersChannel < ApplicationCable::Channel
  def subscribed
    market = Market.find(params[:id])
    stream_for market
  end

  def unsubscribed
    stop_all_streams
  end
end
