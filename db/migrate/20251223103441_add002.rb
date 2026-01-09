class Add002 < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :active, :boolean, default: true
  end
end
