class AddDefaultBlockNumberToBlocks < ActiveRecord::Migration[5.2]
  def change
    change_column_default :blocks, :block_number, 0
  end
end
