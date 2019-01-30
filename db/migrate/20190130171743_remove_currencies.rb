class RemoveCurrencies < ActiveRecord::Migration[5.2]
  def change
  	drop_table :currencies
  end
end
