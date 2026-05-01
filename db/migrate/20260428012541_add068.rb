class Add068 < ActiveRecord::Migration[8.1]
  def change
    add_column :corps, :visto, :boolean, default: false
  end
end
