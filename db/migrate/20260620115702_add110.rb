class Add110 < ActiveRecord::Migration[8.1]
  def change
    remove_column :corps, :balance
  end
end
