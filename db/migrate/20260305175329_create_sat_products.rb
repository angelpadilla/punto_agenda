class CreateSatProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :sat_products do |t|
      t.string :sku
      t.string :name

      t.timestamps
    end
  end
end
