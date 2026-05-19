class CreateBills < ActiveRecord::Migration[8.1]
  def change
    create_table :bills do |t|
      t.references :corp, null: false, foreign_key: true
      t.decimal :costo, precision: 17, scale: 4
      t.decimal :descuento, precision: 17, scale: 4, default: 0.0
      t.string :error
      t.string :folio
      t.decimal :ganancia, precision: 17, scale: 4
      t.string :moneda
      t.text :nota_interna
      t.text :nota_for_corp
      t.text :sat_cfdi
      t.text :sat_sello
      t.string :sat_sello_emisor
      t.string :sat_serial
      t.string :sat_timbre_fecha
      t.string :sat_uuid
      t.string :uso_cfdi
      t.text :xml
      t.string :forma_pago
      t.string :status_pago, default: "pendiente"
      t.string :tipo, default: "remision"
      t.decimal :total, precision: 17, scale: 4
      t.decimal :subtotal, precision: 17, scale: 4
      t.decimal :impuestos, precision: 17, scale: 4

      t.timestamps
    end
  end
end
