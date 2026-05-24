class Add89 < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :canal, :integer, default: 0, null: false
  end
end
