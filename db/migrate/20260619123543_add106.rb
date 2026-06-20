class Add106 < ActiveRecord::Migration[8.1]
  def change
    add_column :customers, :stripe_customer_id, :string
    add_column :customers, :stripe_payment_method_id, :string
  end
end
