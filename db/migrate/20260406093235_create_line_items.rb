class CreateLineItems < ActiveRecord::Migration[8.1]
  def change
    create_table :line_items do |t|
      t.references :item, foreign_key: true
      t.references :order, null: false, foreign_key: true
      t.decimal :cantidad, precision: 17, scale: 4
      t.decimal :precio, precision: 17, scale: 4
      t.decimal :descuento, precision: 17, scale: 4, default: 0.0
      t.decimal :costo, precision: 17, scale: 4, default: 0.0
      t.string :comentario
      t.decimal :iva, precision: 17, scale: 4, default: 16.0
      t.string :error

      t.timestamps
    end
  end
end
