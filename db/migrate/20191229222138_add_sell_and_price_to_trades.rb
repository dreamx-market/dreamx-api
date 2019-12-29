class AddSellAndPriceToTrades < ActiveRecord::Migration[5.2]
  def change
    add_column :trades, :sell, :bool
    add_column :trades, :price, :decimal
  end
end
