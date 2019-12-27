class FixUniqueConstraints < ActiveRecord::Migration[5.2]
  def change
    remove_index :withdraws, [:withdraw_hash, :nonce]
    add_index :withdraws, :withdraw_hash, unique: true
    add_index :withdraws, :nonce, unique: true

    remove_index :orders, [:order_hash, :nonce]
    add_index :orders, :order_hash, unique: true
    add_index :orders, :nonce, unique: true

    remove_index :trades, [:trade_hash, :nonce]
    add_index :trades, :trade_hash, unique: true
    add_index :trades, :nonce, unique: true

    remove_index :order_cancels, [:cancel_hash, :nonce]
    add_index :order_cancels, :cancel_hash, unique: true
    add_index :order_cancels, :nonce, unique: true
  end
end
