class AddBusinessHoursToCorps < ActiveRecord::Migration[8.1]
  def change
    add_column :corps, :business_hours, :text
  end
end
