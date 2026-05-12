class Add78 < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :tel_prefix, :string
  end
end
