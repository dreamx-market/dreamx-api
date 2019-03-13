class AddStatusTransactionHashBlockHashBlockNumberToWithdraws < ActiveRecord::Migration[5.2]
  def change
    add_column :withdraws, :status, :string
    add_column :withdraws, :transaction_hash, :string
    add_column :withdraws, :block_hash, :string
    add_column :withdraws, :block_number, :string
  end
end
