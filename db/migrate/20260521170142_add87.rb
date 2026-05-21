class Add87 < ActiveRecord::Migration[8.1]
  def change
    change_column :corps, :min_book_amount, :decimal, precision: 10, scale: 2, default: nil
  end
end
