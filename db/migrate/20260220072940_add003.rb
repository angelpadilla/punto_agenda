class Add003 < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :corp, null: true, foreign_key: true
    add_column :users, :full_name, :string
  end
end
