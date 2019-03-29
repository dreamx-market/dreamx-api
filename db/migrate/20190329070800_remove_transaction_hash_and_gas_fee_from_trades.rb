class RemoveTransactionHashAndGasFeeFromTrades < ActiveRecord::Migration[5.2]
  def change
    remove_column :trades, :transaction_hash, :string
    remove_column :trades, :gas_fee, :string
  end
end
