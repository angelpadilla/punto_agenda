class Add97 < ActiveRecord::Migration[8.1]
  def change
    change_column :message_events, :status, :integer, default: 0, null: false
  end
end
