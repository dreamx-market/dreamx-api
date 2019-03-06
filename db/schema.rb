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

ActiveRecord::Schema.define(version: 2019_03_06_214943) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "address"
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

  create_table "deposits", force: :cascade do |t|
    t.string "account_address"
    t.string "token_address"
    t.string "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "markets", force: :cascade do |t|
    t.string "base_token_address"
    t.string "quote_token_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["base_token_address"], name: "index_markets_on_base_token_address"
    t.index ["quote_token_address"], name: "index_markets_on_quote_token_address"
  end

  create_table "order_cancels", force: :cascade do |t|
    t.string "order_hash"
    t.string "account_address"
    t.string "nonce"
    t.string "cancel_hash"
    t.string "signature"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "orders", force: :cascade do |t|
    t.string "account_address"
    t.string "give_token_address"
    t.string "give_amount"
    t.string "take_token_address"
    t.string "take_amount"
    t.string "nonce"
    t.string "expiry_timestamp_in_milliseconds"
    t.string "order_hash"
    t.string "signature"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "filled", default: "0"
    t.string "status", default: "open"
    t.string "fee", default: "0"
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
    t.string "account_address"
    t.string "order_hash"
    t.string "amount"
    t.string "nonce"
    t.string "trade_hash"
    t.string "signature"
    t.uuid "uuid", default: -> { "gen_random_uuid()" }
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "fee", default: "0"
    t.string "total", default: "0"
  end

  create_table "withdraws", force: :cascade do |t|
    t.string "account_address"
    t.string "amount"
    t.string "token_address"
    t.string "nonce"
    t.string "withdraw_hash"
    t.string "signature"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "fee"
  end

end
