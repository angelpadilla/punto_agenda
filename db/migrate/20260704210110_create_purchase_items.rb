class CreatePurchaseItems < ActiveRecord::Migration[8.1]
  def change
    create_table :purchase_items do |t|
      t.decimal :cantidad, precision: 17, scale: 4
      t.decimal :precio, precision: 17, scale: 4
      t.decimal :iva, precision: 17, scale: 4, default: 16.0
      t.string :nombre
      t.string :body
      t.string :error
      
      t.references :item, foreign_key: true
      t.references :purchase, null: false, foreign_key: true
      t.timestamps
    end
  end
end
