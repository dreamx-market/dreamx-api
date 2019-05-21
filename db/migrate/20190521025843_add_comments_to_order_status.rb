class AddCommentsToOrderStatus < ActiveRecord::Migration[5.2]
  def up
    change_column :orders, :status, :string, comment: 'open, partially_filled, closed'
  end

  def down
    change_column :orders, :status, :string
  end
end
