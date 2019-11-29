class AddEjectedToAccounts < ActiveRecord::Migration[5.2]
  def change
    add_column :accounts, :ejected, :bool
  end
end
