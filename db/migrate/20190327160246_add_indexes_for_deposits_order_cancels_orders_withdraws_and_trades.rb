class AddIndexesForDepositsOrderCancelsOrdersWithdrawsAndTrades < ActiveRecord::Migration[5.2]
  def change
    add_index :deposits, :transaction_hash
    add_index :order_cancels, :cancel_hash
    add_index :orders, :order_hash
    add_index :trades, :trade_hash
    add_index :withdraws, :withdraw_hash
  end
end
