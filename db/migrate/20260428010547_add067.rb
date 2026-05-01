class Add067 < ActiveRecord::Migration[8.1]
  def change
    add_column :corps, :calendar, :boolean, default: false
    add_column :corps, :online_payments, :boolean, default: false
    add_column :corps, :public_site, :boolean, default: false
  end
end
