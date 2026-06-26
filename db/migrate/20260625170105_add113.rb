class Add113 < ActiveRecord::Migration[8.1]
  def change
    add_column :bills, :nota, :text
    add_column :bills, :num_operacion, :string
  end
end
