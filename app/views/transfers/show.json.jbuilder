json.total @transfers.total_entries
json.page Integer(@transfers.current_page)
json.per_page @transfers.per_page
json.records @transfers, partial: 'transfers/transfer', as: :transfer