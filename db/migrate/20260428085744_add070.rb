class Add070 < ActiveRecord::Migration[8.1]
  def change
    add_column :corps, :facturacion, :boolean, default: false
  end
end
