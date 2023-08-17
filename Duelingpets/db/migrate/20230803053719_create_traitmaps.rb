class CreateTraitmaps < ActiveRecord::Migration[5.2]
  def change
    create_table :traitmaps do |t|
      t.integer :entity_id
      t.integer :entitytype_id
      t.integer :traittype_id
      t.integer :amount

      t.timestamps
    end
  end
end
