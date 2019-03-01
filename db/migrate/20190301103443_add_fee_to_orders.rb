class AddFeeToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :fee, :string, default: '0'
  end
end
