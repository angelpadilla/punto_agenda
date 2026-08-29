class Add121 < ActiveRecord::Migration[8.1]
  def change
    add_column :corps, :printer_nativo, :boolean, default: false
  end
end
