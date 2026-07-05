class CreatePurchases < ActiveRecord::Migration[8.1]
  def change
    create_table :purchases do |t|
      t.decimal :total, precision: 17, scale: 4, default: 0.0
      t.decimal :subtotal, precision: 17, scale: 4, default: 0.0
      t.decimal :impuestos, precision: 17, scale: 4, default: 0.0
      t.decimal :abonado, precision: 17, scale: 4, default: 0.0
      t.decimal :debe, precision: 17, scale: 4, default: 0.0

      t.string :folio, null: false
      t.string :nota_customer
      t.string :nota_admin
      t.text :error

      t.integer :forma_pago, default: 0
      t.integer :status, default: 0
      t.integer :status_pago, default: 0
      t.integer :tipo, default: 0

      t.date :deadline
      t.date :fecha

      t.references :corp, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.references :provider, foreign_key: true
      t.timestamps
    end
  end
end
