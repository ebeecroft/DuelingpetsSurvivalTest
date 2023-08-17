class CreateExchangerates < ActiveRecord::Migration[5.2]
  def change
    create_table :exchangerates do |t|
      t.integer :currency1_id
      t.integer :currency2_id
      t.integer :minrate
      t.integer :currentrate
      t.integer :maxrate

      t.timestamps
    end
  end
end
