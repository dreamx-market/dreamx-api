class AddMakerFeeToTrades < ActiveRecord::Migration[5.2]
  def change
    add_column :trades, :maker_fee, :string, :default => "0"
  end
end
