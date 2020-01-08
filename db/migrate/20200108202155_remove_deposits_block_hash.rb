class RemoveDepositsBlockHash < ActiveRecord::Migration[5.2]
  def change
    remove_column :deposits, :block_hash, :string
  end
end
