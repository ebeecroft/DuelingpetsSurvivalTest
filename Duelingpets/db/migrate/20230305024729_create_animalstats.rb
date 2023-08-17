class CreateAnimalstats < ActiveRecord::Migration[5.2]
  def change
    create_table :animalstats do |t|
      t.integer :value
      t.integer :animaltype_id
      t.integer :stat_id

      t.timestamps
    end
  end
end
