class Add111 < ActiveRecord::Migration[8.1]
  def change
    add_column :deposits, :canal, :integer, default: 0
  end
end
