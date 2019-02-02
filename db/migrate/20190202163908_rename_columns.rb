class RenameColumns < ActiveRecord::Migration[5.2]
  def change
  	rename_column :balances, :token, :token_address
  	rename_column :orders, :account, :account_address
  end
end
