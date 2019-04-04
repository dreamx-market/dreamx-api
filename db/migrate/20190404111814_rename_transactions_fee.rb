class RenameTransactionsFee < ActiveRecord::Migration[5.2]
  def change
    rename_column :transactions, :fee, :gas
  end
end
