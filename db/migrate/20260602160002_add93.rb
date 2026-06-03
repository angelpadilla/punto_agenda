class Add93 < ActiveRecord::Migration[8.1]
  def change
    add_column :bills, :com_vendedor, :decimal, precision: 17, scale: 4, default: 0.0
    add_column :line_items, :com_vendedor, :decimal, precision: 17, scale: 4, default: 0.0
    add_column :items, :com_vendedor, :decimal, precision: 17, scale: 4, default: 0.0
  end
end
