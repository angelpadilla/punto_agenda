class Add114 < ActiveRecord::Migration[8.1]
  def change
    add_column :corps, :banco_clabe, :string
    add_column :corps, :banco_nombre, :string
    add_column :corps, :banco_beneficiario, :string
  end
end
