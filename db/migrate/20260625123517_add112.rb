class Add112 < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :canal, :integer, default: 0, null: false
  end
end
