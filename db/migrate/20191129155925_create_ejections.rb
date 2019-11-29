class CreateEjections < ActiveRecord::Migration[5.2]
  def change
    create_table :ejections do |t|
      t.string :account_address

      t.timestamps
    end
    add_index :ejections, :account_address
  end
end
