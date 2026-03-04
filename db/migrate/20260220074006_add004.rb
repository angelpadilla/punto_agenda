class Add004 < ActiveRecord::Migration[8.1]
  def change
    add_column :corps, :tipo_negocio, :string
    add_column :users, :tel, :string
  end
end
