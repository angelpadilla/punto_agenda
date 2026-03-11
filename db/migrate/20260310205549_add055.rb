class Add055 < ActiveRecord::Migration[8.1]
  def change
    add_reference :brands, :corp, null: true, foreign_key: true
  end
end
