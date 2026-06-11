class Add103 < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :rol, :integer, default: 1
  end
end
