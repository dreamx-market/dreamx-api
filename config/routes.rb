Rails.application.routes.draw do
  resources :transfers, defaults: { format: :json }, param: :account_address, only: [:show]
  resources :chart_data, defaults: { format: :json }, param: :market_symbol
  resources :tickers, defaults: { format: :json }, param: :market_symbol
  resources :order_books, defaults: { format: :json }, param: :market_symbol
  # resources :deposits
  resources :withdraws, defaults: { format: :json }
  resources :order_cancels, defaults: { format: :json }
  resources :trades, defaults: { format: :json }
  resources :balances, defaults: { format: :json }, param: :account_address
  resources :orders, defaults: { format: :json }, param: :order_hash
  get 'return_contract_address', :to => 'helpers#return_contract_address', defaults: { format: :json }
  get 'fees', :to => 'helpers#return_fees', defaults: { format: :json }
  resources :markets, defaults: { format: :json }, only: [:index]
  resources :tokens, defaults: { format: :json }
end
