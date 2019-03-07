class CreateOrderBooks < ActiveRecord::Migration[5.2]
  def change
    create_table :order_books do |t|

      t.timestamps
    end
  end
end
