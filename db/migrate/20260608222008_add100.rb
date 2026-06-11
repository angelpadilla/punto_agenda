class Add100 < ActiveRecord::Migration[8.1]
  def change
    add_column :message_events, :tipo, :integer
  end
end
