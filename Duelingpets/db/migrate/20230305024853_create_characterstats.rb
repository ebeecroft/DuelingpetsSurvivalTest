class CreateCharacterstats < ActiveRecord::Migration[5.2]
  def change
    create_table :characterstats do |t|
      t.integer :value
      t.integer :character_id
      t.integer :stat_id

      t.timestamps
    end
  end
end
