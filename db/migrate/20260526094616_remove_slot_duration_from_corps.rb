class RemoveSlotDurationFromCorps < ActiveRecord::Migration[8.1]
  def change
    remove_column :corps, :slot_duration, :integer
  end
end
