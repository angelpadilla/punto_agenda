class Add063 < ActiveRecord::Migration[8.1]
  def change
    remove_column :customers, :events_count
  end
end
