class Add064 < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :status, :integer, default: 0, null: false
  end
end
