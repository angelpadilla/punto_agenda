class Add115 < ActiveRecord::Migration[8.1]
  def change
    remove_column :bills, :nota
  end
end
