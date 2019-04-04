class RemoveStatusFromWithdraws < ActiveRecord::Migration[5.2]
  def change
    remove_column :withdraws, :status, :string
  end
end
