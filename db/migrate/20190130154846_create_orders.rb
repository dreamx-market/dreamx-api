class CreateOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :orders do |t|
      t.string :account
      t.string :giveTokenAddress
      t.integer :giveAmount
      t.string :takeTokenAddress
      t.integer :takeAmount
      t.integer :nonce
      t.integer :expiryTimestampInMilliseconds
      t.string :orderHash
      t.string :signature

      t.timestamps
    end
  end
end
