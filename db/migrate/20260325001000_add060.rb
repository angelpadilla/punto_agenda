class Add060 < ActiveRecord::Migration[8.1]
  def change
    add_column :customers, :notas, :text
  end
end
