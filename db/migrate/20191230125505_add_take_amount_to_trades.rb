class AddTakeAmountToTrades < ActiveRecord::Migration[5.2]
  def change
    add_column :trades, :take_amount, :decimal
  end
end
