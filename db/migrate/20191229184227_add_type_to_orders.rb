class AddTypeToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :sell, :bool
  end
end
