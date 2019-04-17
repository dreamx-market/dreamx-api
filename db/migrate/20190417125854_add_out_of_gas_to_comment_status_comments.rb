class AddOutOfGasToCommentStatusComments < ActiveRecord::Migration[5.2]
  def up
    change_column :transactions, :status, :string, comment: 'confirmed, unconfirmed, pending, replaced, failed, out_of_gas'
  end

  def down
    change_column :transactions, :status, :string, comment: 'confirmed, unconfirmed, pending, replaced, failed'
  end
end
