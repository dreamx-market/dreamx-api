class RemoveTransactionsBlockNumberAndBlockHash < ActiveRecord::Migration[5.2]
  def change
    remove_column :transactions, :block_hash, :string
    remove_column :transactions, :block_number, :bigint
  end
end
