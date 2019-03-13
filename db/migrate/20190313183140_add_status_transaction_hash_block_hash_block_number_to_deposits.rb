class AddStatusTransactionHashBlockHashBlockNumberToDeposits < ActiveRecord::Migration[5.2]
  def change
    add_column :deposits, :status, :string
    add_column :deposits, :transaction_hash, :string
    add_column :deposits, :block_hash, :string
    add_column :deposits, :block_number, :string
  end
end
