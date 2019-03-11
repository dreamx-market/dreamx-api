class AddMarketSymbolToChartData < ActiveRecord::Migration[5.2]
  def change
    add_column :chart_data, :market_symbol, :string
  end
end
