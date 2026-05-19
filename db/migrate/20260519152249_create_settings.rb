class CreateSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :settings do |t|
      t.string :name
      t.string :domain
      t.string :instagram_url
      t.string :tiktok_url
      t.string :facebook_url
      t.string :phone
      t.string :tel_prefix
      t.string :email
      t.text :head_extra
      t.text :body_extra
      t.text :factura_extra
      t.text :remision_extra
      t.text :cotizacion_extra
      t.string :estado
      t.string :cp
      t.string :calle
      t.string :colonia
      t.string :ciudad
      t.string :localidad
      t.string :num_int
      t.string :num_ext
      t.string :razon
      t.string :rfc
      t.string :regimen
      t.string :key_pass
      t.timestamps
    end
  end
end
