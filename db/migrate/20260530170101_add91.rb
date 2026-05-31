class Add91 < ActiveRecord::Migration[8.1]
  def change
    remove_column :corps, :active
  end
end
