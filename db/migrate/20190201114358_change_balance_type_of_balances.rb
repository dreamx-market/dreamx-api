class ChangeBalanceTypeOfBalances < ActiveRecord::Migration[5.2]
  def change
  	change_column :balances, :balance, :integer, using: 'balance::integer'
  end
end
