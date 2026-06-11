class Add98 < ActiveRecord::Migration[8.1]
  def change
    add_column :message_events, :error, :string
  end
end
