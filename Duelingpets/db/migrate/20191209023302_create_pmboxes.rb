class CreatePmboxes < ActiveRecord::Migration[5.2]
  def change
    create_table :pmboxes do |t|
      t.integer :capacity
      t.boolean :box_open, default: false
      t.integer :user_id

      t.timestamps
    end
  end
end
