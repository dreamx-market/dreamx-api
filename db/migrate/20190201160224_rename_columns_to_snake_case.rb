class RenameColumnsToSnakeCase < ActiveRecord::Migration[5.2]
  def change
  	rename_column :balances, :holdBalance, :hold_balance
  	rename_column :orders, :giveTokenAddress, :give_token_address
  	rename_column :orders, :giveAmount, :give_amount
  	rename_column :orders, :takeTokenAddress, :take_token_address
  	rename_column :orders, :takeAmount, :take_amount
  	rename_column :orders, :expiryTimestampInMilliseconds, :expiry_timestamp_in_milliseconds
  	rename_column :orders, :orderHash, :order_hash
  end
end
