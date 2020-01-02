class AddForeignKeysAndIndexes < ActiveRecord::Migration[5.2]
  def change
    add_reference :balances, :token, foreign_key: true
    add_reference :balances, :account, foreign_key: true

    remove_reference :deposits, :balance
    add_reference :deposits, :account, foreign_key: true
    add_reference :deposits, :token, foreign_key: true
    add_reference :deposits, :balance, foreign_key: true

    add_reference :ejections, :account, foreign_key: true

    add_reference :markets, :base_token, foreign_key: { to_table: :tokens }
    add_reference :markets, :quote_token, foreign_key: { to_table: :tokens }

    remove_reference :orders, :give_balance
    remove_reference :orders, :take_balance
    add_reference :orders, :give_token, foreign_key: { to_table: :tokens }
    add_reference :orders, :take_token, foreign_key: { to_table: :tokens }
    add_reference :orders, :account, foreign_key: true
    add_reference :orders, :give_balance, foreign_key: { to_table: :balances }
    add_reference :orders, :take_balance, foreign_key: { to_table: :balances }
    add_reference :orders, :market, foreign_key: true

    remove_reference :order_cancels, :balance
    add_reference :order_cancels, :account, foreign_key: true
    add_reference :order_cancels, :order, foreign_key: true
    add_reference :order_cancels, :balance, foreign_key: true

    remove_reference :refunds, :balance
    add_reference :refunds, :balance, foreign_key: true

    add_reference :tickers, :market, foreign_key: true

    remove_reference :trades, :give_balance
    remove_reference :trades, :take_balance
    add_reference :trades, :account, foreign_key: true
    add_reference :trades, :order, foreign_key: true
    add_reference :trades, :give_balance, foreign_key: { to_table: :balances }
    add_reference :trades, :take_balance, foreign_key: { to_table: :balances }
    add_reference :trades, :market, foreign_key: true

    remove_reference :transactions, :transactable, polymorphic: true
    add_reference :transactions, :transactable, polymorphic: true

    remove_reference :withdraws, :balance
    add_reference :withdraws, :account, foreign_key: true
    add_reference :withdraws, :token, foreign_key: true
    add_reference :withdraws, :balance, foreign_key: true
  end
end
