class Add108 < ActiveRecord::Migration[8.1]
  def change
    add_column :customers, :card_brand, :string
    add_column :customers, :card_country, :string
    add_column :customers, :card_exp_month, :string
    add_column :customers, :card_exp_year, :string
    add_column :customers, :card_last4, :string

  end
end
