class RemoveTransactionHashFromWithdraws < ActiveRecord::Migration[5.2]
  def change
    remove_column :withdraws, :transaction_hash, :string
  end
end
