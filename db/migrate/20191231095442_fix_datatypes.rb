class FixDatatypes < ActiveRecord::Migration[5.2]
  def up
    change_table :balances do |t|
      t.change_default :balance, nil
      t.change_default :hold_balance, nil
      t.change :balance, :decimal, precision: 1000, scale: 0, default: 0, null: false, using: 'balance::integer'
      t.change :hold_balance, :decimal, precision: 1000, scale: 0, default: 0, null: false, using: 'balance::integer'
    end

    change_table :blocks do |t|
      t.change :block_number, :bigint
    end

    change_table :chart_data do |t|
      t.change :high, :decimal, precision: 32, scale: 16, using: 'high::decimal'
      t.change :low, :decimal, precision: 32, scale: 16, using: 'low::decimal'
      t.change :open, :decimal, precision: 32, scale: 16, using: 'open::decimal'
      t.change :close, :decimal, precision: 32, scale: 16, using: 'close::decimal'
      t.change :volume, :decimal, precision: 32, scale: 16, using: 'volume::decimal'
      t.change :quote_volume, :decimal, precision: 32, scale: 16, using: 'quote_volume::decimal'
      t.change :average, :decimal, precision: 32, scale: 16, using: 'average::decimal'
      t.change :period, :integer, using: 'period::integer'
      t.index :created_at
    end

    change_table :deposits do |t|
      t.index :created_at
      t.change :amount, :decimal, precision: 1000, scale: 0, null: false, using: 'amount::integer'
      t.remove :status
      t.change :block_number, :bigint, null: false, using: 'block_number::integer'
    end

    change_table :markets do |t|
      t.change :status, :string, default: 'disabled', comment: nil
    end

    change_table :order_cancels do |t|
      t.change :nonce, :bigint, null: false, using: 'nonce::integer'
    end

    change_table :orders do |t|
      t.change_default :fee, nil
      t.change_default :filled, nil
      t.change_default :give_amount, nil
      t.change_default :take_amount, nil
      t.change_default :expiry_timestamp_in_milliseconds, nil
      t.change :fee, :decimal, precision: 1000, scale: 0, default: 0, null: false, using: 'fee::integer'
      t.change :filled, :decimal, precision: 1000, scale: 0, default: 0, null: false, using: 'filled::integer'
      t.change :nonce, :bigint, null: false, using: 'nonce::integer'
      t.change :give_amount, :decimal, precision: 1000, scale: 0, null: false, using: 'give_amount::integer'
      t.change :take_amount, :decimal, precision: 1000, scale: 0, null: false, using: 'take_amount::integer'
      t.change :expiry_timestamp_in_milliseconds, :bigint, null: false, using: 'expiry_timestamp_in_milliseconds::integer'
      t.change :status, :string, default: 'open', null: false, comment: nil
    end

    change_table :refunds do |t|
      t.change :amount, :decimal, precision: 1000, scale: 0, null: false, using: 'amount::integer'
    end

    change_table :tickers do |t|
      t.change_default :percent_change, nil
      t.change_default :base_volume, nil
      t.change_default :quote_volume, nil
      t.change :market_symbol, :string, null: false
      t.change :last, :decimal, precision: 32, scale: 16, using: 'last::integer'
      t.change :high, :decimal, precision: 32, scale: 16, using: 'high::integer'
      t.change :low, :decimal, precision: 32, scale: 16, using: 'low::integer'
      t.change :lowest_ask, :decimal, precision: 32, scale: 16, using: 'lowest_ask::integer'
      t.change :highest_bid, :decimal, precision: 32, scale: 16, using: 'highest_bid::integer'
      t.change :percent_change, :decimal, precision: 32, scale: 16, default: 0, using: 'percent_change::integer'
      t.change :base_volume, :decimal, precision: 32, scale: 16, default: 0, using: 'base_volume::integer'
      t.change :quote_volume, :decimal, precision: 32, scale: 16, default: 0, using: 'quote_volume::integer'
    end

    change_table :tokens do |t|
      t.change :decimals, :integer, using: 'decimals::integer'
      t.change :withdraw_minimum, :decimal, precision: 1000, scale: 0, using: 'withdraw_minimum::integer'
      t.change :withdraw_fee, :decimal, precision: 1000, scale: 0, using: 'withdraw_fee::integer'
    end

    change_table :trades do |t|
      t.change_default :fee, nil
      t.change_default :total, nil
      t.change_default :maker_fee, nil
      t.change :amount, :decimal, precision: 1000, scale: 0, null: false, using: 'amount::integer'
      t.change :nonce, :bigint, null: false, using: 'nonce::integer'
      t.change :fee, :decimal, precision: 1000, scale: 0, null: false, using: 'fee::integer'
      t.change :total, :decimal, precision: 1000, scale: 0, null: false, using: 'total::integer'
      t.change :maker_fee, :decimal, precision: 1000, scale: 0, null: false, using: 'maker_fee::integer'
      t.column :sell, :bool
      t.column :price, :decimal, precision: 32, scale: 16
      t.column :take_amount, :decimal, precision: 1000, scale: 0
      t.index :created_at
    end

    change_table :transactions do |t|
      t.change :transactable_id, :bigint
      t.change :gas_limit, :decimal, precision: 1000, scale: 0, null: false, using: 'gas_limit::integer'
      t.change :gas_price, :decimal, precision: 1000, scale: 0, null: false, using: 'gas_price::integer'
      t.change :block_number, :bigint, using: 'block_number::integer'
      t.change :status, :string, comment: nil
      t.change :gas, :decimal, precision: 1000, scale: 0, null: true, using: 'gas::integer'
      t.change :nonce, :bigint, null: false
    end

    drop_table :transfers

    change_table :withdraws do |t|
      t.change :nonce, :bigint, null: false, using: 'nonce::integer'
      t.change :amount, :decimal, precision: 1000, scale: 0, null: false, using: 'amount::integer'
      t.change :fee, :decimal, precision: 1000, scale: 0, null: false, using: 'fee::integer'
      t.index :created_at
    end
  end

  def down
    change_table :balances do |t|
      t.change :balance, :string, default: '0', null: false
      t.change :hold_balance, :string, default: '0', null: false
    end

    change_table :blocks do |t|
      t.change :block_number, :integer
    end

    change_table :chart_data do |t|
      t.change :high, :string
      t.change :low, :string
      t.change :open, :string
      t.change :close, :string
      t.change :volume, :string
      t.change :quote_volume, :string
      t.change :average, :string
      t.change :period, :string
      t.remove_index :created_at
    end

    change_table :deposits do |t|
      t.remove_index :created_at
      t.change :amount, :string, null: false
      t.column :status, :string, null: false
      t.change :block_number, :string, null: false
    end

    change_table :markets do |t|
      t.change :status, :string, default: 'disabled', comment: "active, disabled"
    end

    change_table :order_cancels do |t|
      t.change :nonce, :string, null: false
    end

    change_table :orders do |t|
      t.change :fee, :string, default: '0', null: false
      t.change :filled, :string, default: '0', null: false
      t.change :nonce, :string, null: false
      t.change :give_amount, :string, null: false
      t.change :take_amount, :string, null: false
      t.change :expiry_timestamp_in_milliseconds, :string, null: false
      t.change :status, :string, default: 'open', null: false, comment: 'open, partially_filled, closed'
    end

    change_table :refunds do |t|
      t.change :amount, :string
    end

    change_table :tickers do |t|
      t.change :market_symbol, :string, null: true
      t.change :last, :string
      t.change :high, :string
      t.change :low, :string
      t.change :lowest_ask, :string
      t.change :highest_bid, :string
      t.change :percent_change, :string, default: '0'
      t.change :base_volume, :string, default: '0'
      t.change :quote_volume, :string, default: '0'
    end

    change_table :tokens do |t|
      t.change :decimals, :string
      t.change :withdraw_minimum, :string
      t.change :withdraw_fee, :string
    end

    change_table :trades do |t|
      t.change :amount, :string, null: false
      t.change :nonce, :string, null: false
      t.change :fee, :string, default: '0', null: false
      t.change :total, :string, default: '0', null: false
      t.change :maker_fee, :string, default: '0', null: false
      t.remove :sell, :price, :take_amount
      t.remove_index :created_at
    end

    change_table :transactions do |t|
      t.change :transactable_id, :integer
      t.change :gas_limit, :string
      t.change :gas_price, :string
      t.change :block_number, :string
      t.change :status, :string, comment: "confirmed, unconfirmed, pending, replaced, failed, out_of_gas"
      t.change :gas, :string
      t.change :nonce, :integer, null: false
    end

    create_table :transfers do |t|
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    change_table :withdraws do |t|
      t.change :nonce, :string, null: false
      t.change :amount, :string, null: false
      t.change :fee, :string
      t.remove_index :created_at
    end
  end
end
