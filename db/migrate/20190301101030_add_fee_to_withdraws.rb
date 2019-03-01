class AddFeeToWithdraws < ActiveRecord::Migration[5.2]
  def change
    add_column :withdraws, :fee, :string
  end
end
