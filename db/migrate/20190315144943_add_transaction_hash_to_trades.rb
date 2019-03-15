class AddTransactionHashToTrades < ActiveRecord::Migration[5.2]
  def change
    add_column :trades, :transaction_hash, :string
  end
end
