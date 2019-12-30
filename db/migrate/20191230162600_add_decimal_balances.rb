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
  end

  def down
    change_column :balances, :balance, :string, default: '0'
    change_column :balances, :hold_balance, :string, default: '0'
    change_column :orders, :fee, :string, default: '0'
    change_column :orders, :filled, :string, default: '0'
  end
end
