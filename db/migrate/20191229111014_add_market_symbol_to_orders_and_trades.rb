class AddMarketSymbolToOrdersAndTrades < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :market_symbol, :string
    add_column :trades, :market_symbol, :string
  end
end
