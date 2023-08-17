class CreateDamageoffsets < ActiveRecord::Migration[5.2]
  def change
    create_table :damageoffsets do |t|
      t.string :name
      t.float :value, limit: 53

      t.timestamps
    end
  end
end
