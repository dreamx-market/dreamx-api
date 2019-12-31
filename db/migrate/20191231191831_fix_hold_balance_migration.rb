class FixHoldBalanceMigration < ActiveRecord::Migration[5.2]
  def up
    change_table :balances do |t|
      t.change :hold_balance, :decimal, precision: 1000, scale: 0, default: 0, null: false, using: 'hold_balance::decimal'
    end
  end

  def down
    change_table :balances do |t|
      t.change :hold_balance, :decimal, precision: 1000, scale: 0, default: 0, null: false, using: 'balance::decimal'
    end
  end
end
