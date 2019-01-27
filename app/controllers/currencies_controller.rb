class CurrenciesController < ApplicationController
  # GET /currencies
  def index
    @currencies = Currency.all
  end
end
