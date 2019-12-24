class AddDatabaseContraints < ActiveRecord::Migration[5.2]
  def change
    remove_index :deposits, :transaction_hash
    remove_index :withdraws, :withdraw_hash
    remove_index :orders, :order_hash
    remove_index :trades, :trade_hash
    remove_index :order_cancels, :cancel_hash
    remove_index :ejections, :account_address

    # uniqueness validations must be backed by unique contraints
    add_index :deposits, :transaction_hash, unique: true
    add_index :withdraws, [:withdraw_hash, :nonce], unique: true
    add_index :orders, [:order_hash, :nonce], unique: true
    add_index :trades, [:trade_hash, :nonce], unique: true
    add_index :order_cancels, [:cancel_hash, :nonce], unique: true
    add_index :ejections, :account_address, unique: true

    # presence validations must be backed by null: false contraints
    change_column_null :deposits, :transaction_hash, false
    change_column_null :withdraws, :amount, false
    change_column_null :withdraws, :token_address, false
    change_column_null :withdraws, :nonce, false
    change_column_null :withdraws, :withdraw_hash, false
    change_column_null :withdraws, :signature, false
    change_column_null :orders, :account_address, false
    change_column_null :orders, :give_token_address, false
    change_column_null :orders, :give_amount, false
    change_column_null :orders, :take_token_address, false
    change_column_null :orders, :take_amount, false
    change_column_null :orders, :nonce, false
    change_column_null :orders, :expiry_timestamp_in_milliseconds, false
    change_column_null :orders, :order_hash, false
    change_column_null :orders, :signature, false
    change_column_null :trades, :account_address, false
    change_column_null :trades, :order_hash, false
    change_column_null :trades, :amount, false
    change_column_null :trades, :nonce, false
    change_column_null :trades, :trade_hash, false
    change_column_null :trades, :signature, false
    change_column_null :trades, :fee, false
    change_column_null :trades, :total, false
    change_column_null :trades, :maker_fee, false
    change_column_null :order_cancels, :order_hash, false
    change_column_null :order_cancels, :account_address, false
    change_column_null :order_cancels, :nonce, false
    change_column_null :order_cancels, :cancel_hash, false
    change_column_null :order_cancels, :signature, false

    # inclusion validations must be backed by check contraints
  end
end
