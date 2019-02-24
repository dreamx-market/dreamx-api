class AddFilledToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :filled, :string, :default => "0"
  end
end
