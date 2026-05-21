class Add86 < ActiveRecord::Migration[8.1]
  def change
    add_column :corps, :public_calendar, :boolean, default: false
    add_column :corps, :min_book_amount, :decimal, precision: 10, scale: 2, default: 0.0
  end
end
