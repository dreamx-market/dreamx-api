class AddUniqueConstrants < ActiveRecord::Migration[5.2]
  def change
    add_index :balances, [:account_id, :token_id], unique: true
  end
end
