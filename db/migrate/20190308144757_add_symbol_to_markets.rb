class AddSymbolToMarkets < ActiveRecord::Migration[5.2]
  def change
    add_column :markets, :symbol, :string
  end
end
