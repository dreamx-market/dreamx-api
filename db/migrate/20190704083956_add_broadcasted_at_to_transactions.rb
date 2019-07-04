class AddBroadcastedAtToTransactions < ActiveRecord::Migration[5.2]
  def change
    add_column :transactions, :broadcasted_at, :datetime
  end
end
