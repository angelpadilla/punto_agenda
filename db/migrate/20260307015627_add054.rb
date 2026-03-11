class Add054 < ActiveRecord::Migration[8.1]
  def change
    remove_column :items, :active
  end
end
