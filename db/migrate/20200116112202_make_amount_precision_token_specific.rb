class MakeAmountPrecisionTokenSpecific < ActiveRecord::Migration[5.2]
  def change
    remove_column :markets, :amount_precision, :integer
    add_column :tokens, :amount_precision, :integer
    add_reference :trades, :give_token, foreign_key: { to_table: :tokens }
    add_reference :trades, :take_token, foreign_key: { to_table: :tokens }
  end
end
