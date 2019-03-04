class AddTotalToTrades < ActiveRecord::Migration[5.2]
  def change
    add_column :trades, :total, :string, :default => "0"
  end
end
