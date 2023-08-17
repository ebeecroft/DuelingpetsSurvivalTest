class CreateTraits < ActiveRecord::Migration[5.2]
  def change
    create_table :traits do |t|
      t.string :name
      t.integer :level
      t.integer :user_id

      t.timestamps
    end
  end
end
