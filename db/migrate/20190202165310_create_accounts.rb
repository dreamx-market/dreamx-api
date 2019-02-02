class CreateAccounts < ActiveRecord::Migration[5.2]
  def change
    create_table :accounts do |t|
      t.string :address
    end
    add_index :accounts, :address
  end
end
