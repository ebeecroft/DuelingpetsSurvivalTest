class CreateElementcharts < ActiveRecord::Migration[5.2]
  def change
    create_table :elementcharts do |t|
      t.string :name
      t.datetime :created_on
      t.datetime :updated_on
      t.integer :user_id

      t.timestamps
    end
  end
end
