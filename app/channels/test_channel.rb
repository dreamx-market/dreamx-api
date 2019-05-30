class TestChannel < ApplicationCable::Channel
  def subscribed
    stop_all_streams
    stream_from "test"
    ActionCable.server.broadcast "test", 'HELLO'
  end

  def unsubscribed
    stop_all_streams
  end
end
