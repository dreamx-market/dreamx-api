json.total @tickers.total_entries
json.page Integer(@tickers.current_page)
json.per_page @tickers.per_page
json.records @tickers.records, partial: 'tickers/ticker', as: :ticker
