class Add005 < ActiveRecord::Migration[8.1]
  def change
    add_column :corps, :sku, :string
  end
end
