class CreateWareshelves < ActiveRecord::Migration[5.2]
  def change
    create_table :wareshelves do |t|
      t.string :waretype
      t.integer :warelimit
      t.integer :warehouse_id

      t.timestamps
    end
  end
end
