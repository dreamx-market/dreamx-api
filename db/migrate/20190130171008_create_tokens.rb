class CreateTokens < ActiveRecord::Migration[5.2]
  def change
    create_table :tokens do |t|
      t.string :name
      t.string :address
      t.string :symbol
      t.integer :decimals

      t.timestamps
    end
    add_index :tokens, :address
  end
end
