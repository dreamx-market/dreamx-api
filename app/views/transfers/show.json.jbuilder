json.deposits do
  json.total @transfers[:deposits].total_entries
  json.page Integer(@transfers[:deposits].current_page)
  json.per_page @transfers[:deposits].per_page
  json.records @transfers[:deposits], partial: 'transfers/transfer', as: :transfer
end
json.withdraws do
  json.total @transfers[:withdraws].total_entries
  json.page Integer(@transfers[:withdraws].current_page)
  json.per_page @transfers[:withdraws].per_page
  json.records @transfers[:withdraws], partial: 'transfers/transfer', as: :transfer
end