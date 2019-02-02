Rails.application.routes.draw do
  resources :markets, defaults: {format: :json} 
  resources :balances, defaults: {format: :json}, param: :account_address
  resources :tokens, defaults: {format: :json}
  resources :orders, defaults: {format: :json}
  get 'helpers/return_contract_address', defaults: {format: :json}
end
