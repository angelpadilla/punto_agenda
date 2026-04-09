class CreateDeposits < ActiveRecord::Migration[8.1]
  def change
    create_table :deposits do |t|
      t.decimal :monto, precision: 17, scale: 4
      t.text :xml
      t.text :sat_cfdi
      t.text :sat_sello
      t.text :sat_serial
      t.text :sat_uuid
      t.text :uso_cfdi
      t.string :stamp_date
      t.string :sat_error
      t.string :moneda, default: "MXN"
      t.string :num_operacion
      t.string :forma_pago
      t.integer :tipo, null: false
      t.decimal :comision_terminal, precision: 17, scale: 4, default: "0.0"
      t.belongs_to :depositable, polymorphic: true

      t.timestamps
    end
  end
end
