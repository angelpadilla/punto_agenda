class Add062 < ActiveRecord::Migration[8.1]
  def change
    remove_column :customers, :no_show_count
    add_column :customers, :success_events, :integer, default: 0
    add_column :customers, :failed_events, :integer, default: 0
    add_column :customers, :total_events, :integer, default: 0
  end
end
