class CreateChartData < ActiveRecord::Migration[5.2]
  def change
    create_table :chart_data do |t|
      t.string :high
      t.string :low
      t.string :open
      t.string :close
      t.string :volume
      t.string :quote_volume
      t.string :average
      t.string :period

      t.timestamps
    end
  end
end
