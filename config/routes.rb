Rails.application.routes.draw do
  resources :withdraws
  resources :order_cancels
  resources :trades
  resources :balances, defaults: {format: :json}, param: :account_address
  resources :orders, defaults: {format: :json}
  get 'return_contract_address', :to => 'helpers#return_contract_address', defaults: {format: :json}
  # resources :markets, defaults: {format: :json} 
  # resources :tokens, defaults: {format: :json}
end
