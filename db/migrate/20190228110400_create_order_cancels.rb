class CreateOrderCancels < ActiveRecord::Migration[5.2]
  def change
    create_table :order_cancels do |t|
      t.string :order_hash
      t.string :account_address
      t.string :nonce
      t.string :cancel_hash
      t.string :signature

      t.timestamps
    end
  end
end
