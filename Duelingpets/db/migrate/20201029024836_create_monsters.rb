class CreateMonsters < ActiveRecord::Migration[5.2]
  def change
    create_table :monsters do |t|
      t.string :name
      t.text :description
      t.datetime :created_on
      t.datetime :updated_on
      t.datetime :reviewed_on
      t.integer :user_id
      t.integer :monstertype_id
      t.integer :elementchart_id
      t.boolean :reviewed, default: false

      t.timestamps
    end
  end
end
