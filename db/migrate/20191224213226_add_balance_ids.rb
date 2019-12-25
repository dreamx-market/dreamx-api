class AddBalanceIds < ActiveRecord::Migration[5.2]
  def change
    add_column :deposits, :balance_id, :bigint, null: false
    add_column :orders, :give_balance_id, :bigint, null: false
    add_column :orders, :take_balance_id, :bigint, null: false
    add_column :order_cancels, :balance_id, :bigint, null: false
    add_column :trades, :give_balance_id, :bigint, null: false
    add_column :trades, :take_balance_id, :bigint, null: false
    add_column :withdraws, :balance_id, :bigint, null: false
  end
end
