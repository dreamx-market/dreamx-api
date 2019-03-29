class ChangeTransactionHash < ActiveRecord::Migration[5.2]
  def change
    rename_column :transactions, :hash, :transaction_hash
  end
end
