class Add075 < ActiveRecord::Migration[8.1]
  def change
    change_column :corps, :timbres, :integer, default: 0
  end
end
