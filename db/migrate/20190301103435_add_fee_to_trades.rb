class AddFeeToTrades < ActiveRecord::Migration[5.2]
  def change
    add_column :trades, :fee, :string, default: '0'
  end
end
