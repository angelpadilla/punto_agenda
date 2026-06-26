class Add116 < ActiveRecord::Migration[8.1]
  def change
    add_column :bills, :retiro_clabe, :string
    add_column :bills, :retiro_banco, :string
    add_column :bills, :retiro_beneficiario, :string

  end
end
