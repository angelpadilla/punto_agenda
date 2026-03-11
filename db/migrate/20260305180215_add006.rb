class Add006 < ActiveRecord::Migration[8.1]
  def change
    add_reference :items, :corp, null: false, foreign_key: true
  end
end
