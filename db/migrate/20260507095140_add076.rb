class Add076 < ActiveRecord::Migration[8.1]
  def change
    add_column :customers, :canal, :string, default: "interno"
  end
end
