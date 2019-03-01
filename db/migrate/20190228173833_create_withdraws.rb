class CreateWithdraws < ActiveRecord::Migration[5.2]
  def change
    create_table :withdraws do |t|
      t.string :account_address
      t.string :amount
      t.string :token_address
      t.string :nonce
      t.string :withdraw_hash
      t.string :signature

      t.timestamps
    end
  end
end
