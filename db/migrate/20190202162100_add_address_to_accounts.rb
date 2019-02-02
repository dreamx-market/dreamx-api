class AddAddressToAccounts < ActiveRecord::Migration[5.2]
  def change
    add_column :accounts, :address, :string
    add_index :accounts, :address
  end
end
