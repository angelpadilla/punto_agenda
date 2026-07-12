class Add119 < ActiveRecord::Migration[8.1]
  def change
    change_column_null :bills, :corp_id, true
    change_column_null :tickets, :corp_id, true
  end
end
