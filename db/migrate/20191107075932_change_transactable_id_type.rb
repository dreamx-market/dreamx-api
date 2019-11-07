class ChangeTransactableIdType < ActiveRecord::Migration[5.2]
  def up
    change_column :transactions, :transactable_id, :integer, using: 'transactable_id::integer'
  end

  def down
    change_column :transactions, :transactable_id, :string
  end
end
