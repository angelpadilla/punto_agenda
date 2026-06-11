class AddRecurrenceToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :recurrence_id, :string
    add_column :events, :recurrence_rule, :string
    add_column :events, :recurrence_ends_on, :date
    add_column :events, :recurrence_index, :integer
    add_index :events, :recurrence_id
  end
end
