class CreateWareobjects < ActiveRecord::Migration[5.2]
  def change
    create_table :wareobjects do |t|
      t.string :type
      t.integer :price
      t.integer :quantity
      t.integer :wareshelf_id
      t.integer :wareobject_id

      t.timestamps
    end
  end
end
