class AddCommentForTransactionStatus < ActiveRecord::Migration[5.2]
  def up
    change_column :transactions, :status, :string, comment: 'confirmed, unconfirmed, pending, replaced'
  end

  def down
    change_column :transactions, :status, :string
  end
end
