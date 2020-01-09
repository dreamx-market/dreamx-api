class RemoveBlocksBlockHashAndParentHash < ActiveRecord::Migration[5.2]
  def change
    remove_column :blocks, :block_hash, :string
    remove_column :blocks, :parent_hash, :string
  end
end
