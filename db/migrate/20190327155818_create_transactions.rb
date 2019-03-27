class CreateTransactions < ActiveRecord::Migration[5.2]
  def change
    create_table :transactions do |t|
      t.string :action_type
      t.string :action_hash
      t.string :raw
      t.string :gas_limit
      t.string :gas_price
      t.string :hash
      t.string :block_hash
      t.string :block_number
      t.string :status
      t.string :nonce

      t.timestamps
    end
    add_index :transactions, :hash
  end
end
