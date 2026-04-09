class Add065 < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :seller_id, :integer
  end
end
