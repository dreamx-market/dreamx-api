class AddBalanceIds < ActiveRecord::Migration[5.2]
  def change
    add_column :deposits, :balance_id, :bigint
    add_column :orders, :give_balance_id, :bigint
    add_column :orders, :take_balance_id, :bigint
    add_column :order_cancels, :balance_id, :bigint
    add_column :trades, :give_balance_id, :bigint
    add_column :trades, :take_balance_id, :bigint
    add_column :withdraws, :balance_id, :bigint

    Deposit.all.each do |d|
      d.set_balance
      d.save
    end
    Order.all.each do |o|
      o.set_balance
      o.save
    end
    OrderCancel.all.each do |o|
      o.set_balance
      o.save
    end
    Trade.all.each do |t|
      t.set_balance
      t.save
    end
    Withdraw.all.each do |w|
      w.set_balance
      w.save
    end

    change_column_null :deposits, :balance_id, false
    change_column_null :orders, :give_balance_id, false
    change_column_null :orders, :take_balance_id, false
    change_column_null :order_cancels, :balance_id, false
    change_column_null :trades, :give_balance_id, false
    change_column_null :trades, :take_balance_id, false
    change_column_null :withdraws, :balance_id, false
  end
end
