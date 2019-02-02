class AddDefaultValuesForBalances < ActiveRecord::Migration[5.2]
  def change
  	change_column :balances, :balance, :string, :default => '0'
  	change_column :balances, :hold_balance, :string, :default => '0'
  end
end
