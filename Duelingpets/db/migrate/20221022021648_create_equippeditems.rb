class CreateEquippeditems < ActiveRecord::Migration[5.2]
  def change
    create_table :equippeditems do |t|
      t.integer :current_durability
      t.integer :initial_durability
      t.integer :equip_id
      t.integer :item_id

      t.timestamps
    end
  end
end
