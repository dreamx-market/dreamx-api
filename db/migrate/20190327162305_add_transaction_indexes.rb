class AddTransactionIndexes < ActiveRecord::Migration[5.2]
  def change
    add_index :transactions, :transactable_type
    add_index :transactions, :transactable_id
  end
end
