class AddNullConstraints < ActiveRecord::Migration[5.2]
  def change
    change_column_null :trades, :sell, false
    change_column_null :trades, :price, false
    change_column_null :trades, :take_amount, false
  end
end
