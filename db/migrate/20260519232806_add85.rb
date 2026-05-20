class Add85 < ActiveRecord::Migration[8.1]
  def change
    change_column :items, :stock, :decimal, precision: 17, scale: 4, default: nil
  end
end
