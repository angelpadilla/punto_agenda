class Add118 < ActiveRecord::Migration[8.1]
  def change
    add_column :tickets, :error, :string
    add_column :tickets, :nota_admin, :string
  end
end
