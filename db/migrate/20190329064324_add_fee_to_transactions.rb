class AddFeeToTransactions < ActiveRecord::Migration[5.2]
  def change
    add_column :transactions, :fee, :string
  end
end
