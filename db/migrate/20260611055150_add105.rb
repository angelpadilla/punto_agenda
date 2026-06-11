class Add105 < ActiveRecord::Migration[8.1]
  def change
    change_column :posts, :visits, :bigint, default: 0
  end
end
