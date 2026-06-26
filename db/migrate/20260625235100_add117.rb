class Add117 < ActiveRecord::Migration[8.1]
  def change
    add_column :bills, :retiro_deposits, :text
  end
end
