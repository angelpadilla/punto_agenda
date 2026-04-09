class Add057 < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :alerta_stock, :decimal, precision: 12, scale: 4
  end
end
