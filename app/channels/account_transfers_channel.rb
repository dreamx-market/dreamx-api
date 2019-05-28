class AccountTransfersChannel < ApplicationCable::Channel
  def subscribed
    stop_all_streams
    stream_from "account_transfers:#{params[:account_address]}"
  end

  def unsubscribed
    stop_all_streams
  end
end
