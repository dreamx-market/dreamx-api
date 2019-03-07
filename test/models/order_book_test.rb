require 'test_helper'

class OrderBookTest < ActiveSupport::TestCase
  # setup do
  #   orderbook = OrderBook.find_by_symbol("ONE_TWO")
  #   @buybook = orderbook[:buybook]
  #   @sellbook = orderbook[:sellbook]
  # end

  # test "buybook is sorted by descending price" do
  #   @buybook.each_with_index do |order, i|
  #     next_order = @buybook[i + 1]
  #     if (next_order)
  #       assert order.price >= next_order.price
  #     end
  #   end
  # end

  # test "sellbook is sorted by ascending price" do
  #   @sellbook.each_with_index do |order, i|
  #     next_order = @sellbook[i + 1]
  #     if (next_order)
  #       assert order.price <= next_order.price
  #     end
  #   end
  # end

  # test "orders of a similar price are sorted by ascending date in buybook" do
  #   @buybook.each_with_index do |order, i|
  #     next_order = @buybook[i + 1]
  #     if (next_order && order.price === next_order.price)
  #       assert order.created_at.to_i < next_order.created_at.to_i
  #     end
  #   end
  # end

  # test "orders of a similar price are sorted by ascending date in sellbook" do
  #   @sellbook.each_with_index do |order, i|
  #     next_order = @sellbook[i + 1]
  #     if (next_order && order.price === next_order.price)
  #       assert order.created_at.to_i < next_order.created_at.to_i
  #     end
  #   end
  # end
end
