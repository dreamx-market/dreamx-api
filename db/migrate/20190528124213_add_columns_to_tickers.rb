class AddColumnsToTickers < ActiveRecord::Migration[5.2]
  def change
    add_column :tickers, :market_symbol, :string
    add_column :tickers, :last, :string
    add_column :tickers, :high, :string
    add_column :tickers, :low, :string
    add_column :tickers, :lowest_ask, :string
    add_column :tickers, :highest_bid, :string
    add_column :tickers, :percent_change, :string, :default => "0"
    add_column :tickers, :base_volume, :string, :default => "0"
    add_column :tickers, :quote_volume, :string, :default => "0"
  end
end
