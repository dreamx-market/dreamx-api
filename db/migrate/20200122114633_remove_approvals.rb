class RemoveApprovals < ActiveRecord::Migration[5.2]
  def change
    drop_table :approvals
  end
end
