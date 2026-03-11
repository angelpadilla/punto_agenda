class Add056 < ActiveRecord::Migration[8.1]
  def change
    remove_column :items, :brandd
  end
end
