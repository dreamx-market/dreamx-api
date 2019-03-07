json.total @markets.total_entries
json.page Integer(@markets.current_page)
json.per_page @markets.per_page
json.records @markets, partial: 'markets/market', as: :market
