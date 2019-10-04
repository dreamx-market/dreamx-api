class CreateTransactionLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :transaction_logs do |t|
      t.references :transaction, foreign_key: true
      t.text :message

      t.timestamps
    end
  end
end
