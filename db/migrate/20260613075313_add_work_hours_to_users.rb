class AddWorkHoursToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :work_start_time, :time
    add_column :users, :work_end_time, :time
  end
end
