class CreateMarkets < ActiveRecord::Migration[5.2]
  def change
    create_table :markets do |t|
      t.string :base_token_address
      t.string :quote_token_address

      t.timestamps
    end
    add_index :markets, :base_token_address
    add_index :markets, :quote_token_address
  end
end
