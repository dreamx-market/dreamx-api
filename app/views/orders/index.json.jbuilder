json.total @orders.total_entries
json.page Integer(@orders.current_page)
json.per_page @orders.per_page
json.records @orders, partial: 'orders/order', as: :order
