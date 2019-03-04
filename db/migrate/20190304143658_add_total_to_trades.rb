class AddTotalToTrades < ActiveRecord::Migration[5.2]
  def change
    add_column :trades, :total, :string
  end
end
