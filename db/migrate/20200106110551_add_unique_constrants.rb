class AddUniqueConstrants < ActiveRecord::Migration[5.2]
  def change
    add_index :balances, [:account_id, :token_id], unique: true

    change_table :tokens do |t|
      t.remove_index :address
      t.index :name, unique: true
      t.index :address, unique: true
      t.index :symbol, unique: true
    end
  end
end
