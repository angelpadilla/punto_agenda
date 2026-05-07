class Add077 < ActiveRecord::Migration[8.1]
  def change
    add_column :corps, :tipo_plan, :integer, default: 0, null: false
  end
end
