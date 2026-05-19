class CreateBillItems < ActiveRecord::Migration[8.1]
  def change
    create_table :bill_items do |t|
      t.string :nombre
      t.decimal :cantidad,  precision: 17, scale: 4
      t.string :comentario
      t.decimal :costo,  precision: 17, scale: 4, default: 0.0
      t.decimal :descuento,  precision: 17, scale: 4, default: 0.0
      t.string :error
      t.decimal :iva,  precision: 17, scale: 4, default: 16.0
      t.references :bill, null: false, foreign_key: true
      t.decimal :precio,  precision: 17, scale: 4

      t.timestamps
    end
  end
end
