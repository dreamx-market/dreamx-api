json.bid do
  json.partial! "order_books/order_book", order_book: @order_book[:buy_book]
end
json.ask do
  json.partial! "order_books/order_book", order_book: @order_book[:sell_book]
end