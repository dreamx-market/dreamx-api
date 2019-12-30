class AddDecimalBalances < ActiveRecord::Migration[5.2]
  def up
    change_column_default :balances, :balance, nil
    change_column_default :balances, :hold_balance, nil
    change_column_default :orders, :fee, nil
    change_column_default :orders, :filled, nil

    change_column :balances, :balance, :decimal, default: 0.0, using: 'balance::integer', null: false
    change_column :balances, :hold_balance, :decimal, default: 0.0, using: 'hold_balance::integer', null: false
    change_column :orders, :fee, :decimal, default: 0.0, using: 'fee::integer', null: false
    change_column :orders, :filled, :decimal, default: 0.0, using: 'filled::integer', null: false
    change_column :transactions, :nonce, :bigint, null: false
    change_column :order_cancels, :nonce, :bigint, null: false, using: 'nonce::integer'
    change_column :orders, :nonce, :bigint, null: false, using: 'nonce::integer'
    change_column :trades, :nonce, :bigint, null: false, using: 'nonce::integer'
    change_column :withdraws, :nonce, :bigint, null: false, using: 'nonce::integer'
  end

  def down
    change_column :balances, :balance, :string, default: '0'
    change_column :balances, :hold_balance, :string, default: '0'
    change_column :orders, :fee, :string, default: '0'
    change_column :orders, :filled, :string, default: '0'
    change_column :transactions, :nonce, :integer
    change_column :order_cancels, :nonce, :string
    change_column :orders, :nonce, :string
    change_column :trades, :nonce, :string
    change_column :withdraws, :nonce, :string
  end
end
