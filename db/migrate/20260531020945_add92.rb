class Add92 < ActiveRecord::Migration[8.1]
  def change
    remove_column :corps, :last_payment_at
    add_column :corps, :subscription_next_billing_date, :datetime
  end
end
