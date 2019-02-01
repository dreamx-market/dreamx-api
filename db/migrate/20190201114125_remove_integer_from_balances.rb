class RemoveIntegerFromBalances < ActiveRecord::Migration[5.2]
  def change
    remove_column :balances, :integer, :string
  end
end
