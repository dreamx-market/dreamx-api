class CreateDeposits < ActiveRecord::Migration[5.2]
  def change
    create_table :deposits do |t|
      t.string :account_address
      t.string :token_address
      t.string :amount

      t.timestamps
    end
  end
end
