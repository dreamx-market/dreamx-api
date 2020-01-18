class AddTransactionHashAndBlockNumberToEjections < ActiveRecord::Migration[5.2]
  def change
    add_column :ejections, :transaction_hash, :string, null: false
    add_column :ejections, :block_number, :bigint, null: false
    add_index :ejections, :transaction_hash
  end
end
