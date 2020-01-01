class AddMissingReferences < ActiveRecord::Migration[5.2]
  def change
    add_reference :chart_data, :market, foreign_key: true
  end
end
