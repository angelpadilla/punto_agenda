class Add81 < ActiveRecord::Migration[8.1]
  def change
    add_column :corps, :tel_prefix, :string
  end
end
