json.total order_book.total_entries
json.page Integer(order_book.current_page)
json.per_page order_book.per_page
json.records order_book, partial: 'orders/order', as: :order
