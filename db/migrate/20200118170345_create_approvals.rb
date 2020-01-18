class CreateApprovals < ActiveRecord::Migration[5.2]
  def change
    create_table :approvals do |t|
      t.references :account, foreign_key: true
      t.references :balance, foreign_key: true
      t.references :token, foreign_key: true
      t.string :account_address, index: true
      t.string :token_address, index: true
      t.string :transaction_hash
      t.index :transaction_hash, unique: true
      t.bigint :block_number
      t.decimal :amount, precision: 1000, scale: 0, null: false

      t.timestamps
    end
  end
end
