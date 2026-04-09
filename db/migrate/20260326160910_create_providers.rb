class CreateProviders < ActiveRecord::Migration[8.1]
  def change
    create_table :providers do |t|
      t.string :razon
      t.string :calle
      t.string :ciudad
      t.string :colonia
      t.string :cp
      t.string :email
      t.string :estado
      t.string :localidad
      t.text :notas
      t.string :num_ext
      t.string :num_int
      t.string :regimen, default: "616"
      t.string :rfc, default: "XAXX010101000"
      t.string :tel
      t.references :corp, null: false, foreign_key: true

      t.timestamps
    end
  end
end
