# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_01_08_202155) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "address"
    t.boolean "ejected", default: false
    t.index ["address"], name: "index_accounts_on_address"
  end

  create_table "balances", force: :cascade do |t|
    t.string "account_address"
    t.string "token_address"
    t.decimal "balance", precision: 1000, default: "0", null: false
    t.decimal "hold_balance", precision: 1000, default: "0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "fraud", default: false
    t.bigint "token_id", null: false
    t.bigint "account_id", null: false
    t.index ["account_address"], name: "index_balances_on_account_address"
    t.index ["account_id", "token_id"], name: "index_balances_on_account_id_and_token_id", unique: true
    t.index ["account_id"], name: "index_balances_on_account_id"
    t.index ["token_id"], name: "index_balances_on_token_id"
  end

  create_table "blocks", force: :cascade do |t|
    t.string "block_hash"
    t.string "parent_hash"
    t.bigint "block_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "chart_data", force: :cascade do |t|
    t.decimal "high", precision: 32, scale: 16
    t.decimal "low", precision: 32, scale: 16
    t.decimal "open", precision: 32, scale: 16
    t.decimal "close", precision: 32, scale: 16
    t.decimal "volume", precision: 32, scale: 16
    t.decimal "quote_volume", precision: 32, scale: 16
    t.decimal "average", precision: 32, scale: 16
    t.integer "period"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "market_symbol"
    t.bigint "market_id", null: false
    t.index ["created_at"], name: "index_chart_data_on_created_at"
    t.index ["market_id"], name: "index_chart_data_on_market_id"
  end

  create_table "deposits", force: :cascade do |t|
    t.string "account_address", null: false
    t.string "token_address", null: false
    t.decimal "amount", precision: 1000, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "transaction_hash", null: false
    t.bigint "block_number", null: false
    t.bigint "account_id", null: false
    t.bigint "token_id", null: false
    t.bigint "balance_id", null: false
    t.index ["account_id"], name: "index_deposits_on_account_id"
    t.index ["balance_id"], name: "index_deposits_on_balance_id"
    t.index ["created_at"], name: "index_deposits_on_created_at"
    t.index ["token_id"], name: "index_deposits_on_token_id"
    t.index ["transaction_hash"], name: "index_deposits_on_transaction_hash", unique: true
  end

  create_table "ejections", force: :cascade do |t|
    t.string "account_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "account_id", null: false
    t.index ["account_address"], name: "index_ejections_on_account_address", unique: true
    t.index ["account_id"], name: "index_ejections_on_account_id"
  end

  create_table "markets", force: :cascade do |t|
    t.string "base_token_address"
    t.string "quote_token_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "symbol"
    t.string "status", default: "disabled"
    t.bigint "base_token_id", null: false
    t.bigint "quote_token_id", null: false
    t.index ["base_token_address"], name: "index_markets_on_base_token_address"
    t.index ["base_token_id"], name: "index_markets_on_base_token_id"
    t.index ["quote_token_address"], name: "index_markets_on_quote_token_address"
    t.index ["quote_token_id"], name: "index_markets_on_quote_token_id"
  end

  create_table "order_cancels", force: :cascade do |t|
    t.string "order_hash", null: false
    t.string "account_address", null: false
    t.bigint "nonce", null: false
    t.string "cancel_hash", null: false
    t.string "signature", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "account_id", null: false
    t.bigint "order_id", null: false
    t.bigint "balance_id", null: false
    t.index ["account_id"], name: "index_order_cancels_on_account_id"
    t.index ["balance_id"], name: "index_order_cancels_on_balance_id"
    t.index ["cancel_hash"], name: "index_order_cancels_on_cancel_hash", unique: true
    t.index ["nonce"], name: "index_order_cancels_on_nonce", unique: true
    t.index ["order_id"], name: "index_order_cancels_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "account_address", null: false
    t.string "give_token_address", null: false
    t.decimal "give_amount", precision: 1000, null: false
    t.string "take_token_address", null: false
    t.decimal "take_amount", precision: 1000, null: false
    t.bigint "nonce", null: false
    t.bigint "expiry_timestamp_in_milliseconds", null: false
    t.string "order_hash", null: false
    t.string "signature", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "filled", precision: 1000, default: "0", null: false
    t.string "status", default: "open", null: false
    t.decimal "fee", precision: 1000, default: "0", null: false
    t.string "market_symbol", null: false
    t.boolean "sell"
    t.decimal "price", precision: 32, scale: 16
    t.bigint "give_token_id", null: false
    t.bigint "take_token_id", null: false
    t.bigint "account_id", null: false
    t.bigint "give_balance_id", null: false
    t.bigint "take_balance_id", null: false
    t.bigint "market_id", null: false
    t.index ["account_id"], name: "index_orders_on_account_id"
    t.index ["give_balance_id"], name: "index_orders_on_give_balance_id"
    t.index ["give_token_id"], name: "index_orders_on_give_token_id"
    t.index ["market_id"], name: "index_orders_on_market_id"
    t.index ["market_symbol"], name: "index_orders_on_market_symbol"
    t.index ["nonce"], name: "index_orders_on_nonce", unique: true
    t.index ["order_hash"], name: "index_orders_on_order_hash", unique: true
    t.index ["take_balance_id"], name: "index_orders_on_take_balance_id"
    t.index ["take_token_id"], name: "index_orders_on_take_token_id"
  end

  create_table "refunds", force: :cascade do |t|
    t.decimal "amount", precision: 1000, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "balance_id", null: false
    t.index ["balance_id"], name: "index_refunds_on_balance_id"
  end

  create_table "tickers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "market_symbol", null: false
    t.decimal "last", precision: 32, scale: 16
    t.decimal "high", precision: 32, scale: 16
    t.decimal "low", precision: 32, scale: 16
    t.decimal "lowest_ask", precision: 32, scale: 16
    t.decimal "highest_bid", precision: 32, scale: 16
    t.decimal "percent_change", precision: 32, scale: 16, default: "0.0"
    t.decimal "base_volume", precision: 32, scale: 16, default: "0.0"
    t.decimal "quote_volume", precision: 32, scale: 16, default: "0.0"
    t.bigint "market_id", null: false
    t.index ["market_id"], name: "index_tickers_on_market_id"
  end

  create_table "tokens", force: :cascade do |t|
    t.string "name"
    t.string "address"
    t.string "symbol"
    t.integer "decimals"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "withdraw_minimum", precision: 1000
    t.decimal "withdraw_fee", precision: 1000
    t.index ["address"], name: "index_tokens_on_address", unique: true
    t.index ["name"], name: "index_tokens_on_name", unique: true
    t.index ["symbol"], name: "index_tokens_on_symbol", unique: true
  end

  create_table "trades", force: :cascade do |t|
    t.string "account_address", null: false
    t.string "order_hash", null: false
    t.decimal "amount", precision: 1000, null: false
    t.bigint "nonce", null: false
    t.string "trade_hash", null: false
    t.string "signature", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "fee", precision: 1000, null: false
    t.decimal "total", precision: 1000, null: false
    t.decimal "maker_fee", precision: 1000, null: false
    t.string "market_symbol", null: false
    t.boolean "sell", null: false
    t.decimal "price", precision: 32, scale: 16, null: false
    t.decimal "take_amount", precision: 1000, null: false
    t.bigint "account_id", null: false
    t.bigint "order_id", null: false
    t.bigint "give_balance_id", null: false
    t.bigint "take_balance_id", null: false
    t.bigint "market_id", null: false
    t.index ["account_id"], name: "index_trades_on_account_id"
    t.index ["created_at"], name: "index_trades_on_created_at"
    t.index ["give_balance_id"], name: "index_trades_on_give_balance_id"
    t.index ["market_id"], name: "index_trades_on_market_id"
    t.index ["market_symbol"], name: "index_trades_on_market_symbol"
    t.index ["nonce"], name: "index_trades_on_nonce", unique: true
    t.index ["order_hash"], name: "index_trades_on_order_hash"
    t.index ["order_id"], name: "index_trades_on_order_id"
    t.index ["take_balance_id"], name: "index_trades_on_take_balance_id"
    t.index ["trade_hash"], name: "index_trades_on_trade_hash", unique: true
  end

  create_table "transactions", force: :cascade do |t|
    t.decimal "gas_limit", precision: 1000, null: false
    t.decimal "gas_price", precision: 1000, null: false
    t.string "transaction_hash"
    t.string "block_hash"
    t.bigint "block_number"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "gas", precision: 1000
    t.bigint "nonce", null: false
    t.datetime "broadcasted_at"
    t.text "hex"
    t.string "transactable_type", null: false
    t.bigint "transactable_id", null: false
    t.index ["transactable_type", "transactable_id"], name: "index_transactions_on_transactable_type_and_transactable_id"
    t.index ["transaction_hash"], name: "index_transactions_on_transaction_hash"
  end

  create_table "withdraws", force: :cascade do |t|
    t.string "account_address", null: false
    t.decimal "amount", precision: 1000, null: false
    t.string "token_address", null: false
    t.bigint "nonce", null: false
    t.string "withdraw_hash", null: false
    t.string "signature", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "fee", precision: 1000, null: false
    t.bigint "account_id", null: false
    t.bigint "token_id", null: false
    t.bigint "balance_id", null: false
    t.index ["account_id"], name: "index_withdraws_on_account_id"
    t.index ["balance_id"], name: "index_withdraws_on_balance_id"
    t.index ["created_at"], name: "index_withdraws_on_created_at"
    t.index ["nonce"], name: "index_withdraws_on_nonce", unique: true
    t.index ["token_id"], name: "index_withdraws_on_token_id"
    t.index ["withdraw_hash"], name: "index_withdraws_on_withdraw_hash", unique: true
  end

  add_foreign_key "balances", "accounts"
  add_foreign_key "balances", "tokens"
  add_foreign_key "chart_data", "markets"
  add_foreign_key "deposits", "accounts"
  add_foreign_key "deposits", "balances"
  add_foreign_key "deposits", "tokens"
  add_foreign_key "ejections", "accounts"
  add_foreign_key "markets", "tokens", column: "base_token_id"
  add_foreign_key "markets", "tokens", column: "quote_token_id"
  add_foreign_key "order_cancels", "accounts"
  add_foreign_key "order_cancels", "balances"
  add_foreign_key "order_cancels", "orders"
  add_foreign_key "orders", "accounts"
  add_foreign_key "orders", "balances", column: "give_balance_id"
  add_foreign_key "orders", "balances", column: "take_balance_id"
  add_foreign_key "orders", "markets"
  add_foreign_key "orders", "tokens", column: "give_token_id"
  add_foreign_key "orders", "tokens", column: "take_token_id"
  add_foreign_key "refunds", "balances"
  add_foreign_key "tickers", "markets"
  add_foreign_key "trades", "accounts"
  add_foreign_key "trades", "balances", column: "give_balance_id"
  add_foreign_key "trades", "balances", column: "take_balance_id"
  add_foreign_key "trades", "markets"
  add_foreign_key "trades", "orders"
  add_foreign_key "withdraws", "accounts"
  add_foreign_key "withdraws", "balances"
  add_foreign_key "withdraws", "tokens"
end
