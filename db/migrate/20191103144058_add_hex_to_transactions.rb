class AddHexToTransactions < ActiveRecord::Migration[5.2]
  def change
    add_column :transactions, :hex, :text
  end
end
