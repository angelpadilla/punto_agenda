class Add061 < ActiveRecord::Migration[8.1]
  def change
    ## special counters
    add_column :items, :orders_count, :integer, default: 0
    add_column :items, :total_revenue, :decimal, precision: 17, scale: 2, default: 0.0
    add_column :items, :average_duration_event, :decimal, precision: 15, scale: 2, default: 0.0
    add_column :customers, :orders_count, :integer, default: 0
    add_column :customers, :events_count, :integer, default: 0
    add_column :customers, :no_show_count, :integer, default: 0
    add_column :customers, :total_spent, :decimal, precision: 17, scale: 2, default: 0.0
    add_column :users, :completed_events, :integer, default: 0
    add_column :users, :average_rating, :integer, default: 0
  end
end
