class Add82 < ActiveRecord::Migration[8.1]
  def change
    remove_column :customers, :limite_credito
    remove_column :customers, :tipo
  end
end
