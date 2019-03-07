json.bid do
  # buybook is sorted by desc price and asc date
  sorted_order_book = @order_book[:buybook].sort_by { |order| [-order.price, order.created_at.to_i] }
  json.partial! "order_books/order_book", order_book: @order_book[:buybook], sorted_order_book: sorted_order_book
end
json.ask do
  # sellbook is sorted by asc price and asc date
  sorted_order_book = @order_book[:sellbook].sort_by { |order| [order.price, order.created_at.to_i] }
  json.partial! "order_books/order_book", order_book: @order_book[:sellbook], sorted_order_book: sorted_order_book
end