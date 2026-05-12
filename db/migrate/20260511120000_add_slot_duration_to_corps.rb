class AddSlotDurationToCorps < ActiveRecord::Migration[8.1]
  def change
    add_column :corps, :slot_duration, :integer, default: 15, null: false
  end
end
