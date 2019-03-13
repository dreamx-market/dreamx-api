json.bid do
  # buybook is sorted by desc price and asc date
  json.partial! "order_books/order_book", order_book: @order_book[:buybook]
end
json.ask do
  # sellbook is sorted by asc price and asc date
  json.partial! "order_books/order_book", order_book: @order_book[:sellbook]
end