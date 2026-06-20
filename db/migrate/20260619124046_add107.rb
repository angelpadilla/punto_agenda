class Add107 < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :stripe_payment_id, :string
  end
end
