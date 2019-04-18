class ChangeTransactionsNonceType < ActiveRecord::Migration[5.2]
  def change
    remove_column :transactions, :nonce
    add_column :transactions, :nonce, :integer
  end
end
