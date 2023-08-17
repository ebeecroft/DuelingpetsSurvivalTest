class CreateAnimalcurrencies < ActiveRecord::Migration[5.2]
  def change
    create_table :animalcurrencies do |t|
      t.integer :animaltype_id
      t.integer :currencylevel_id
      t.integer :currency_id

      t.timestamps
    end
  end
end
