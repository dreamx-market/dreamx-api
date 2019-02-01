class UseStringsForNumberColumns < ActiveRecord::Migration[5.2]
  def change
  	change_column :balances, :balance, :string
  	change_column :balances, :hold_balance, :string
  	change_column :orders, :give_amount, :string
  	change_column :orders, :take_amount, :string
  	change_column :orders, :nonce, :string
  	change_column :orders, :expiry_timestamp_in_milliseconds, :string
  	change_column :tokens, :decimals, :string
  end
end
