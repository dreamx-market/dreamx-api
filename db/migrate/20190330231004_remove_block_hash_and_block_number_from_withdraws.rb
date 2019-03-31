class RemoveBlockHashAndBlockNumberFromWithdraws < ActiveRecord::Migration[5.2]
  def change
    remove_column :withdraws, :block_hash, :string
    remove_column :withdraws, :block_number, :string
  end
end
