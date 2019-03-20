Rails.application.routes.draw do
  # resources :blocks
  get 'return_contract_address', :to => 'helpers#return_contract_address', defaults: { format: :json }
  get 'fees', :to => 'helpers#return_fees', defaults: { format: :json }
  resources :transfers, defaults: { format: :json }, param: :account_address, only: [:show]
  resources :chart_data, defaults: { format: :json }, param: :market_symbol, only: [:show]
  resources :tickers, defaults: { format: :json }, param: :market_symbol, only: [:show, :index]
  resources :order_books, defaults: { format: :json }, param: :market_symbol, only: [:show]
  # resources :deposits
  resources :withdraws, defaults: { format: :json }, only: [:create, :show]
  resources :order_cancels, defaults: { format: :json }, only: [:create, :show]
  resources :trades, defaults: { format: :json }, only: [:create, :index, :show]
  resources :balances, defaults: { format: :json }, param: :account_address, only: [:show]
  resources :orders, defaults: { format: :json }, param: :order_hash, only: [:index, :show, :create]
  resources :markets, defaults: { format: :json }, only: [:index]
  resources :tokens, defaults: { format: :json }, only: [:index]
end
