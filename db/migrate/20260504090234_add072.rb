class Add072 < ActiveRecord::Migration[8.1]
  def change
    add_column :customers, :tel_prefix, :string
  end
end
