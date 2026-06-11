class Add101 < ActiveRecord::Migration[8.1]
  def change
    add_reference :message_events, :customer, foreign_key: true
  end
end
