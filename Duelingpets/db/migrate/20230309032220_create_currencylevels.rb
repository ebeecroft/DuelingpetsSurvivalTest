class CreateCurrencylevels < ActiveRecord::Migration[5.2]
  def change
    create_table :currencylevels do |t|
      t.string :name

      t.timestamps
    end
  end
end
