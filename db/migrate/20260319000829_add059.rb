class Add059 < ActiveRecord::Migration[8.1]
  def change
    add_column :customers, :limite_credito, :decimal, precision: 17, scale: 2, default: 0.0
  end
end
