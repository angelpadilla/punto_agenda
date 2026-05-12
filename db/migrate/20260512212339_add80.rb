class Add80 < ActiveRecord::Migration[8.1]
  def change
    add_column :corps, :active, :boolean, default: false, null: false
  end
end
