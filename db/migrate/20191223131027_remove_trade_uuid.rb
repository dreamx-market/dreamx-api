class RemoveTradeUuid < ActiveRecord::Migration[5.2]
  def change
    remove_column :trades, :uuid
  end
end
