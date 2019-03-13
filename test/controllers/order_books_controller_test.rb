require 'test_helper'

class OrderBooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @order_book = "ONE_TWO"
  end

  # test "should get index" do
  #   get order_books_url, as: :json
  #   assert_response :success
  # end

  # test "should create order_book" do
  #   assert_difference('OrderBook.count') do
  #     post order_books_url, params: { order_book: {  } }, as: :json
  #   end

  #   assert_response 201
  # end

  test "should show order_book" do
    get order_book_url(@order_book, { :per_page => 2 }), as: :json
    assert_response :success
  end

  # test "should update order_book" do
  #   patch order_book_url(@order_book), params: { order_book: {  } }, as: :json
  #   assert_response 200
  # end

  # test "should destroy order_book" do
  #   assert_difference('OrderBook.count', -1) do
  #     delete order_book_url(@order_book), as: :json
  #   end

  #   assert_response 204
  # end
end
