class CreateCorps < ActiveRecord::Migration[8.1]
  def change
    create_table :corps do |t|
      t.string :name
      t.string :phone
      t.string :whatsapp
      t.string :email
      t.string :tiktok_url
      t.string :facebook_url
      t.string :instagram_url
      t.string :text_factura
      t.string :text_remision
      t.string :text_cotizacion
      t.string :razon
      t.string :rfc
      t.string :regimen
      t.string :key_pass
      t.string :estado
      t.string :cp
      t.string :ciudad
      t.string :colonia
      t.string :localidad
      t.string :calle
      t.string :num_ext
      t.string :num_int
      t.integer :timbres

      t.timestamps
    end
  end
end
