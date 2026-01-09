class Add001 < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :tipo, :string, default: "usuario"
  end
end
