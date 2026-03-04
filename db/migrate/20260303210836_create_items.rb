class CreateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :items do |t|
      t.string :sku
      t.string :name
      t.text :desc
      t.string :brandd
      t.decimal :cost, precision: 17, scale: 4
      t.decimal :offer, precision: 17, scale: 4
      t.decimal :price, precision: 17, scale: 4
      t.decimal :price2, precision: 17, scale: 4
      t.decimal :price3, precision: 17, scale: 4
      t.string :unidad
      t.string :bar_code
      t.string :error
      t.integer :status, default: 0
      t.boolean :active, default: true
      t.integer :cate
      t.string :garantia
      t.decimal :stock, precision: 17, scale: 4, default: "0.0"
      t.references :sat_product, null: false, foreign_key: true
      t.references :brand, foreign_key: true

      t.timestamps
    end
  end
end
