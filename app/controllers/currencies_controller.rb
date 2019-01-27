class CurrenciesController < ApplicationController
  # GET /currencies
  def index
    @currencies = Currency.all

    render json: @currencies
  end
end
