class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.string :tipo
      t.string :status_pago
      t.string :forma_pago
      t.decimal :total, precision: 17, scale: 4
      t.decimal :subtotal, precision: 17, scale: 4
      t.decimal :impuestos, precision: 17, scale: 4
      t.decimal :descuento, precision: 17, scale: 4, default: "0.0"
      t.decimal :costo, precision: 17, scale: 4
      t.decimal :costo_terminal, precision: 17, scale: 4
      t.decimal :ganancia, precision: 17, scale: 4
      t.decimal :debe, precision: 17, scale: 4, default: "0.0"
      t.decimal :abonado, precision: 17, scale: 4, default: "0.0"
      t.string :folio
      t.text :nota_interna
      t.text :nota_customer
      t.string :error
      t.date :deadline
      t.date :fecha
      t.text :xml
      t.text :sat_cfdi
      t.text :sat_sello
      t.string :sat_serial
      t.string :sat_uuid
      t.string :uso_cfdi
      t.string :sat_timbre_fecha
      t.string :moneda, default: "MXN"
      t.string :sat_sello_emisor
      t.references :user, foreign_key: true
      t.references :customer, foreign_key: true
      t.references :corp, null: false, foreign_key: true
      t.timestamps
    end
  end
end
