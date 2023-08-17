class CreateTraittypes < ActiveRecord::Migration[5.2]
  def change
    create_table :traittypes do |t|
      t.string :name

      t.timestamps
    end
  end
end
