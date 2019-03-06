class AddFraudToBalances < ActiveRecord::Migration[5.2]
  def change
    add_column :balances, :fraud, :boolean, :default => false
  end
end
