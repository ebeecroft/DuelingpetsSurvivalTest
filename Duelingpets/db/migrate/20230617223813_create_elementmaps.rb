class CreateElementmaps < ActiveRecord::Migration[5.2]
  def change
    create_table :elementmaps do |t|
      t.integer :elementchart_id
      t.integer :element_id
      t.integer :damageoffset_id

      t.timestamps
    end
  end
end
