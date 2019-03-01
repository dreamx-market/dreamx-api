class AddMinimumWithdrawAndFeeToTokens < ActiveRecord::Migration[5.2]
  def change
    add_column :tokens, :withdraw_minimum, :string
    add_column :tokens, :withdraw_fee, :string
  end
end
