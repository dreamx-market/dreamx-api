json.total @trades.total_entries
json.page Integer(@trades.current_page)
json.per_page @trades.per_page
json.records @trades, partial: 'trades/trade', as: :trade
