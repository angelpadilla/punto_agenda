class Add83 < ActiveRecord::Migration[8.1]
  def change
    add_column :corps, :stripe_customer_id, :string
    add_column :corps, :card_brand, :string
    add_column :corps, :card_last4, :string
    add_column :corps, :card_exp_month, :integer
    add_column :corps, :card_exp_year, :integer
    add_column :corps, :card_name, :string
    add_column :corps, :card_country, :string
    add_column :corps, :stripe_payment_method_id, :string
    add_column :corps, :status, :string, default: "probando"
    add_column :corps, :status_message, :string
    add_column :corps, :discount, :decimal, precision: 15, scale: 2, default: 0.0
    add_column :corps, :last_payment_at, :datetime
    add_column :corps, :stripe_subscription_id, :string
    add_column :corps, :subscription_trial_end, :datetime
    add_column :corps, :subscription_trial_start, :datetime
    add_column :corps, :subscription_started_at, :datetime
    add_column :corps, :subscription_updated_at, :datetime
    add_column :corps, :subscription_cancelled_at, :datetime
    add_column :corps, :payment_attempts, :integer, default: 0
  end
end
