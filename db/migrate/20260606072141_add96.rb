class Add96 < ActiveRecord::Migration[8.1]
  def change
    add_column :corps, :sms, :integer, default: 0
    add_column :corps, :balance, :decimal, precision: 17, scale: 2, default: 0.0
  end
end
