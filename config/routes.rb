Rails.application.routes.draw do
  get 'helpers/return_contract_address', defaults: {format: :json}
  resources :currencies, defaults: {format: :json}
end
