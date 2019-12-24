class AddDatabaseContraints < ActiveRecord::Migration[5.2]
  def change
    remove_index :deposits, :transaction_hash
    remove_index :withdraws, :withdraw_hash
    # remove_index :orders, :order_hash
    # remove_index :trades, :trade_hash
    # remove_index :order_cancels, :cancel_hash

    # uniqueness validations must be backed by unique contraints
    add_index :deposits, :transaction_hash, unique: true
    add_index :withdraws, [:withdraw_hash, :nonce], unique: true
    # add_index :orders, [:order_hash, :nonce], unique: true
    # add_index :trades, [:trade_hash, :nonce], unique: true

    # presence validations must be backed by null: false contraints
    change_column_null :deposits, :transaction_hash, false
    change_column_null :withdraws, :amount, false
    change_column_null :withdraws, :token_address, false
    change_column_null :withdraws, :nonce, false
    change_column_null :withdraws, :withdraw_hash, false
    change_column_null :withdraws, :signature, false

    # inclusion validations must be backed by check contraints
  end
end
