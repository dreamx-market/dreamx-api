class ChangeTransactionsColumnNames < ActiveRecord::Migration[5.2]
  def change
    rename_column :transactions, :action_type, :transactable_type
    rename_column :transactions, :action_hash, :transactable_id
  end
end
