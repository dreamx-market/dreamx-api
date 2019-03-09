class CreateTickers < ActiveRecord::Migration[5.2]
  def change
    create_table :tickers do |t|

      t.timestamps
    end
  end
end
