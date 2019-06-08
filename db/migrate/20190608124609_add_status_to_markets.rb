class AddStatusToMarkets < ActiveRecord::Migration[5.2]
  def change
    add_column :markets, :status, :string, default: 'disabled', comment: 'active, disabled'
  end
end
