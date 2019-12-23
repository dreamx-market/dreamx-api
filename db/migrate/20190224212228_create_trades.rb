class CreateTrades < ActiveRecord::Migration[5.2]
  def change
    create_table :trades do |t|
      t.string :account_address
      t.string :order_hash
      t.string :amount
      t.string :nonce
      t.string :trade_hash
      t.string :signature
      t.uuid :uuid, default: 'gen_random_uuid()'

      t.timestamps
    end
  end
end
