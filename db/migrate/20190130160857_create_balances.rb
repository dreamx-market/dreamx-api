class CreateBalances < ActiveRecord::Migration[5.2]
  def change
    create_table :balances do |t|
      t.string :account
      t.string :token
      t.string :balance
      t.string :integer
      t.integer :holdBalance

      t.timestamps
    end
    add_index :balances, :account
  end
end
