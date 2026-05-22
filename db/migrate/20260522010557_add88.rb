class Add88 < ActiveRecord::Migration[8.1]
  def change
    add_column :bill_items, :stripe_payment_intent_id, :string
  end
end
