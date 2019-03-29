class RemoveRawFromTransactions < ActiveRecord::Migration[5.2]
  def change
    remove_column :transactions, :raw, :string
  end
end
