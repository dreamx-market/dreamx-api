class AddNullConstraintsForReferences < ActiveRecord::Migration[5.2]
  def change
    add_index :trades, :market_symbol
    add_index :orders, :market_symbol

    # change_column_null :balances, :token_id, false
    # change_column_null :balances, :account_id, false
    # change_column_null :deposits, :account_id, false
    # change_column_null :deposits, :token_id, false
    # change_column_null :deposits, :balance_id, false
    # change_column_null :ejections, :account_id, false
    # change_column_null :markets, :base_token_id, false
    # change_column_null :markets, :quote_token_id, false
    # change_column_null :orders, :give_token_id, false
    # change_column_null :orders, :take_token_id, false
    # change_column_null :orders, :account_id, false
    # change_column_null :orders, :give_balance_id, false
    # change_column_null :orders, :take_balance_id, false
    # change_column_null :orders, :market_id, false
    # change_column_null :order_cancels, :account_id, false
    # change_column_null :order_cancels, :order_id, false
    # change_column_null :order_cancels, :balance_id, false
    # change_column_null :refunds, :balance_id, false
    # change_column_null :tickers, :market_id, false
    # change_column_null :trades, :account_id, false
    # change_column_null :trades, :order_id, false
    # change_column_null :trades, :give_balance_id, false
    # change_column_null :trades, :take_balance_id, false
    # change_column_null :trades, :market_id, false
    # change_column_null :transactions, :transactable_type, false
    # change_column_null :transactions, :transactable_id, false
    # change_column_null :withdraws, :account_id, false
    # change_column_null :withdraws, :token_id, false
    # change_column_null :withdraws, :balance_id, false
    # change_column_null :chart_data, :market_id, false
  end
end
