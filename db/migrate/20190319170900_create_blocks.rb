class CreateBlocks < ActiveRecord::Migration[5.2]
  def change
    create_table :blocks do |t|
      t.string :block_hash
      t.string :parent_hash
      t.integer :block_number

      t.timestamps
    end
  end
end
