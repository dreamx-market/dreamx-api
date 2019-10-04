class CreateRefunds < ActiveRecord::Migration[5.2]
  def change
    create_table :refunds do |t|
      t.references :balance, foreign_key: true
      t.string :amount

      t.timestamps
    end
  end
end
