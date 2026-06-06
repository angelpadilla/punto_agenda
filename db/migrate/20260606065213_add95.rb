class Add95 < ActiveRecord::Migration[8.1]
  def change
    remove_column :bill_items, :stripe_payment_intent_id
    add_column :bills, :stripe_payment_id, :string
    add_column :deposits, :stripe_payment_id, :string
  end
end
