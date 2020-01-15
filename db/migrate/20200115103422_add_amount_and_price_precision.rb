class AddAmountAndPricePrecision < ActiveRecord::Migration[5.2]
  def change
    add_column :markets, :amount_precision, :integer
    add_column :markets, :price_precision, :integer
  end
end
