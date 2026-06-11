class Add99 < ActiveRecord::Migration[8.1]
  def change
    remove_column :message_events, :error, :string
    add_column :message_events, :response, :string
  end
end
