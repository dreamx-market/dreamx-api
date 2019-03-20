class CreateBlocks < ActiveRecord::Migration[5.2]
  def change
    create_table :blocks do |t|
      t.string :hash
      t.integer :number

      t.timestamps
    end
  end
end
