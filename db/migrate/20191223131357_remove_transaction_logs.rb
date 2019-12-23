class RemoveTransactionLogs < ActiveRecord::Migration[5.2]
  def change
    drop_table :transaction_logs
  end
end
