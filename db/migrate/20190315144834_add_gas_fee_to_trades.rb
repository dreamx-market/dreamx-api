class AddGasFeeToTrades < ActiveRecord::Migration[5.2]
  def change
    add_column :trades, :gas_fee, :string
  end
end
