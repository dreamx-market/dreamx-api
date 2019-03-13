json.deposits do
  json.total @transfer[:deposits].total_entries
  json.page Integer(@transfer[:deposits].current_page)
  json.per_page @transfer[:deposits].per_page
  json.records @transfer[:deposits], partial: 'transfers/transfer', as: :transfer
end
json.withdraws do
  json.total @transfer[:withdraws].total_entries
  json.page Integer(@transfer[:withdraws].current_page)
  json.per_page @transfer[:withdraws].per_page
  json.records @transfer[:withdraws], partial: 'transfers/transfer', as: :transfer
end