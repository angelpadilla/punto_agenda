class Add104 < ActiveRecord::Migration[8.1]
  def change
    remove_column :posts, :rol
    add_column :admins, :rol, :integer, default: 1
  end
end
