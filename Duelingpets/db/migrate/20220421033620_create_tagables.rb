class CreateTagables < ActiveRecord::Migration[5.2]
  def change
    create_table :tagables do |t|
      t.integer :table_id
      t.string :table_type
      t.integer :tag_id

      t.timestamps
    end
  end
end
