class Add94 < ActiveRecord::Migration[8.1]
  def change
    remove_column :bills, :com_vendedor
    add_column :orders, :com_vendedor, :decimal, precision: 17, scale: 4, default: 0.0
  end
end
