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

ActiveRecord::Schema.define(version: 2019_12_25_205517) do

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
    t.string "balance", default: "0"
    t.string "hold_balance", default: "0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "fraud", default: false
    t.index ["account_address"], name: "index_balances_on_account_address"
  end

  create_table "blocks", force: :cascade do |t|
    t.string "block_hash"
    t.string "parent_hash"
    t.integer "block_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "chart_data", force: :cascade do |t|
    t.string "high"
    t.string "low"
    t.string "open"
    t.string "close"
    t.string "volume"
    t.string "quote_volume"
    t.string "average"
    t.string "period"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "market_symbol"
  end

  create_table "deposits", force: :cascade do |t|
    t.string "account_address", null: false
    t.string "token_address", null: false
    t.string "amount", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", null: false
    t.string "transaction_hash", null: false
    t.string "block_hash", null: false
    t.string "block_number", null: false
    t.bigint "balance_id", null: false
    t.index ["transaction_hash"], name: "index_deposits_on_transaction_hash", unique: true
  end

  create_table "ejections", force: :cascade do |t|
    t.string "account_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_address"], name: "index_ejections_on_account_address", unique: true
  end

  create_table "markets", force: :cascade do |t|
    t.string "base_token_address"
    t.string "quote_token_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "symbol"
    t.string "status", default: "disabled", comment: "active, disabled"
    t.index ["base_token_address"], name: "index_markets_on_base_token_address"
    t.index ["quote_token_address"], name: "index_markets_on_quote_token_address"
  end

  create_table "order_cancels", force: :cascade do |t|
    t.string "order_hash", null: false
    t.string "account_address", null: false
    t.string "nonce", null: false
    t.string "cancel_hash", null: false
    t.string "signature", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "balance_id", null: false
    t.index ["cancel_hash", "nonce"], name: "index_order_cancels_on_cancel_hash_and_nonce", unique: true
  end

  create_table "orders", force: :cascade do |t|
    t.string "account_address", null: false
    t.string "give_token_address", null: false
    t.string "give_amount", null: false
    t.string "take_token_address", null: false
    t.string "take_amount", null: false
    t.string "nonce", null: false
    t.string "expiry_timestamp_in_milliseconds", null: false
    t.string "order_hash", null: false
    t.string "signature", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "filled", default: "0", null: false
    t.string "status", default: "open", null: false, comment: "open, partially_filled, closed"
    t.string "fee", default: "0", null: false
    t.bigint "give_balance_id", null: false
    t.bigint "take_balance_id", null: false
    t.index ["order_hash", "nonce"], name: "index_orders_on_order_hash_and_nonce", unique: true
  end

  create_table "refunds", force: :cascade do |t|
    t.bigint "balance_id"
    t.string "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["balance_id"], name: "index_refunds_on_balance_id"
  end

  create_table "tickers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "market_symbol"
    t.string "last"
    t.string "high"
    t.string "low"
    t.string "lowest_ask"
    t.string "highest_bid"
    t.string "percent_change", default: "0"
    t.string "base_volume", default: "0"
    t.string "quote_volume", default: "0"
  end

  create_table "tokens", force: :cascade do |t|
    t.string "name"
    t.string "address"
    t.string "symbol"
    t.string "decimals"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "withdraw_minimum"
    t.string "withdraw_fee"
    t.index ["address"], name: "index_tokens_on_address"
  end

  create_table "trades", force: :cascade do |t|
    t.string "account_address", null: false
    t.string "order_hash", null: false
    t.string "amount", null: false
    t.string "nonce", null: false
    t.string "trade_hash", null: false
    t.string "signature", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "fee", default: "0", null: false
    t.string "total", default: "0", null: false
    t.string "maker_fee", default: "0", null: false
    t.bigint "give_balance_id", null: false
    t.bigint "take_balance_id", null: false
    t.index ["trade_hash", "nonce"], name: "index_trades_on_trade_hash_and_nonce", unique: true
  end

  create_table "transactions", force: :cascade do |t|
    t.string "transactable_type"
    t.integer "transactable_id"
    t.string "gas_limit"
    t.string "gas_price"
    t.string "transaction_hash"
    t.string "block_hash"
    t.string "block_number"
    t.string "status", comment: "confirmed, unconfirmed, pending, replaced, failed, out_of_gas"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "gas"
    t.integer "nonce"
    t.datetime "broadcasted_at"
    t.text "hex"
    t.index ["transactable_id"], name: "index_transactions_on_transactable_id"
    t.index ["transactable_type"], name: "index_transactions_on_transactable_type"
    t.index ["transaction_hash"], name: "index_transactions_on_transaction_hash"
  end

  create_table "transfers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "withdraws", force: :cascade do |t|
    t.string "account_address", null: false
    t.string "amount", null: false
    t.string "token_address", null: false
    t.string "nonce", null: false
    t.string "withdraw_hash", null: false
    t.string "signature", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "fee"
    t.bigint "balance_id", null: false
    t.index ["withdraw_hash", "nonce"], name: "index_withdraws_on_withdraw_hash_and_nonce", unique: true
  end

  add_foreign_key "refunds", "balances"
end
