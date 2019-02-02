json.total @balances.length
json.page Integer(@balances.current_page)
json.per_page @balances.per_page
json.records @balances, partial: 'balances/balance', as: :balance
