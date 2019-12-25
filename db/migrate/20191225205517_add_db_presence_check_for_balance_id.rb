class AddDbPresenceCheckForBalanceId < ActiveRecord::Migration[5.2]
  def change
    change_column_null :deposits, :balance_id, false
    change_column_null :orders, :give_balance_id, false
    change_column_null :orders, :take_balance_id, false
    change_column_null :order_cancels, :balance_id, false
    change_column_null :trades, :give_balance_id, false
    change_column_null :trades, :take_balance_id, false
    change_column_null :withdraws, :balance_id, false
  end
end
