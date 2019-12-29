class AddMarketSymbolConstraintsForOrdersAndTrades < ActiveRecord::Migration[5.2]
  def change
    change_column_null :orders, :market_symbol, false
    change_column_null :trades, :market_symbol, false
  end
end
