class RemoveOrderBooks < ActiveRecord::Migration[5.2]
  def change
    drop_table :order_books
  end
end
